#!/usr/bin/env python3
"""Render tenant configuration and database provisioning (requires Helm and PyYAML)."""

from pathlib import Path
import subprocess
import tempfile
import unittest

import yaml


CHART = Path(__file__).resolve().parents[1] / "chart"


def render(values):
    with tempfile.NamedTemporaryFile(mode="w", suffix=".yaml") as overrides:
        yaml.safe_dump(values, overrides)
        overrides.flush()
        result = subprocess.run(
            ["helm", "template", "test", str(CHART), "-f", overrides.name],
            check=True, capture_output=True, text=True,
        )
    return [doc for doc in yaml.safe_load_all(result.stdout) if doc]


class MultitenancyTests(unittest.TestCase):
    def test_disabled_by_default(self):
        docs = render({})
        self.assertFalse(any(d["metadata"]["name"] == "damap-tenants" for d in docs))
        self.assertFalse(any(d["kind"] == "Database" for d in docs))

    def test_tenant_fallback_and_replacement(self):
        # Omitted/empty maps use examples. A non-empty map replaces the examples,
        # even when a custom tenant uses the same ID as an example.
        for tenants in (None, {}, {"institution": {"title": "Institution"}},
                        {"tenant_1": {"title": "Real tenant"}, "research": {}}):
            for mode in ("simple", "external", "cnpg"):
                for auto_create in (False, True):
                    with self.subTest(tenants=tenants, mode=mode, auto_create=auto_create):
                        multitenancy = {"enabled": True, "autoCreateDatabases": auto_create}
                        if tenants is not None:
                            multitenancy["tenants"] = tenants
                        docs = render({"damap": {"multitenancy": multitenancy},
                                       "postgres": {"mode": mode}})
                        expected = tenants or yaml.safe_load((CHART / "files/default-tenants.yaml").read_text())
                        secret = next(d for d in docs if d["metadata"]["name"] == "damap-tenants")
                        config = yaml.safe_load(secret["stringData"]["tenants.yaml"])
                        tenant_config = config["damap"]["tenants"]
                        tenant_list = tenant_config["tenant-list"]
                        self.assertEqual(set(tenant_list.split(",")) if tenant_list else set(), set(expected))
                        self.assertEqual(tenant_config["tenant-configs"], expected)
                        quarkus = config["%multitenant"]["quarkus"]
                        self.assertEqual(set(quarkus["datasource"]), set(expected))
                        self.assertEqual(set(quarkus["liquibase"]), set(expected))
                        databases = [d["spec"]["name"] for d in docs if d["kind"] == "Database"]
                        self.assertEqual(set(databases), set(expected) if auto_create and mode == "cnpg" else set())
                        scripts = [c["command"][-1] for d in docs if d["kind"] == "Deployment"
                                   for c in d["spec"]["template"]["spec"].get("initContainers", [])
                                   if c["name"] == "multitenant-db-check"]
                        self.assertEqual(len(scripts), int(auto_create and mode != "cnpg"))
                        if scripts:
                            creation_lines = [line.strip() for line in scripts[0].splitlines()
                                              if 'CREATE DATABASE' in line]
                            self.assertEqual(creation_lines, [
                                '-c "CREATE DATABASE \\"' + tenant + '\\" OWNER \\"$PGUSER\\" TEMPLATE template0"'
                                for tenant in sorted(expected)
                            ])


if __name__ == "__main__":
    unittest.main()
