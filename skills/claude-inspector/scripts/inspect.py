#!/usr/bin/env python3
"""
Claude Inspector - Validate .claude/ directory structure and skills/subagents classification

Usage:
    uv run .claude/skills/claude-inspector/scripts/inspect.py
    uv run .claude/skills/claude-inspector/scripts/inspect.py --include-global
    uv run .claude/skills/claude-inspector/scripts/inspect.py --output report.json
"""

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional


class ClaudeInspector:
    """Inspect .claude/ directory structure and validate skills/subagents classification"""

    # Classification signals
    SUBAGENT_SIGNALS = [
        "workflow", "multi-step", "phase", "pipeline",
        "Task tool", "subagent", "delegation",
        "large output", "parallel", "independent",
        "Phase 1", "Phase 2", "Phase 3", "Phase 4",
        "Step 1", "Step 2", "Step 3"
    ]

    SKILL_SIGNALS = [
        "reference", "guide", "pattern", "style",
        "quick", "simple", "single", "transform",
        "template", "inline", "fast execution"
    ]

    def __init__(self, base_dir: Path, include_global: bool = False):
        self.base_dir = base_dir
        self.include_global = include_global
        self.findings: List[Dict[str, Any]] = []
        self.structure_issues: List[Dict[str, Any]] = []
        self.frontmatter_issues: List[Dict[str, Any]] = []
        self.file_issues: List[Dict[str, Any]] = []

    def run(self) -> Dict[str, Any]:
        """Run full inspection"""
        # Check project-level .claude/
        project_claude = self.base_dir / ".claude"
        if project_claude.exists():
            self.inspect_claude_dir(project_claude, scope="project")

        # Check global ~/.claude/ if requested
        if self.include_global:
            global_claude = Path.home() / ".claude"
            if global_claude.exists():
                self.inspect_claude_dir(global_claude, scope="global")

        return self.generate_report()

    def inspect_claude_dir(self, claude_dir: Path, scope: str):
        """Inspect a .claude/ directory"""
        # Check directory structure
        self.check_directory_structure(claude_dir, scope)

        # Inspect skills
        skills_dir = claude_dir / "skills"
        if skills_dir.exists():
            for skill_dir in skills_dir.iterdir():
                if skill_dir.is_dir():
                    self.inspect_skill(skill_dir, scope, claude_dir)

        # Inspect subagents
        agents_dir = claude_dir / "agents"
        if agents_dir.exists():
            for agent_file in agents_dir.glob("*.md"):
                self.inspect_subagent(agent_file, scope, claude_dir)

    def _get_relative_path(self, path: Path, scope: str) -> str:
        """Get relative path based on scope"""
        if scope == "global":
            # For global scope, return path relative to home directory
            return str(path.relative_to(Path.home()))
        else:
            # For project scope, return path relative to base_dir
            return str(path.relative_to(self.base_dir))

    def check_directory_structure(self, claude_dir: Path, scope: str):
        """Check if .claude/ follows recommended structure"""
        expected_files = ["settings.json"]
        optional_files = ["settings.local.json", "CLAUDE.md", "CLAUDE.local.md", ".mcp.json"]
        expected_dirs = ["skills", "agents"]
        optional_dirs = ["rules", "hooks"]

        # Check for unexpected top-level items
        for item in claude_dir.iterdir():
            if item.name.startswith("."):
                continue
            if item.is_file():
                if item.name not in expected_files + optional_files:
                    self.structure_issues.append({
                        "severity": "info",
                        "location": self._get_relative_path(item, scope),
                        "issue": f"Unexpected file in .claude/: {item.name}",
                        "scope": scope
                    })
            elif item.is_dir():
                if item.name not in expected_dirs + optional_dirs:
                    self.structure_issues.append({
                        "severity": "warning",
                        "location": self._get_relative_path(item, scope),
                        "issue": f"Unexpected directory in .claude/: {item.name}",
                        "scope": scope
                    })

    def inspect_skill(self, skill_dir: Path, scope: str, claude_dir: Path):
        """Inspect a skill directory"""
        skill_md = skill_dir / "SKILL.md"

        # Check SKILL.md exists
        if not skill_md.exists():
            self.structure_issues.append({
                "severity": "error",
                "location": self._get_relative_path(skill_dir, scope),
                "issue": "Missing required SKILL.md file",
                "scope": scope
            })
            return

        # Parse frontmatter and content
        frontmatter, content = self.parse_markdown(skill_md)

        # Validate frontmatter
        self.validate_skill_frontmatter(frontmatter, skill_md, scope)

        # Check for unnecessary files
        self.check_skill_files(skill_dir, scope)

        # Analyze classification
        self.analyze_skill_classification(skill_dir, frontmatter, content, scope)

    def inspect_subagent(self, agent_file: Path, scope: str, claude_dir: Path):
        """Inspect a subagent file"""
        # Parse frontmatter and content
        frontmatter, content = self.parse_markdown(agent_file)

        # Validate frontmatter
        self.validate_subagent_frontmatter(frontmatter, agent_file, scope)

        # Check naming convention
        if not re.match(r'^[a-z][a-z0-9]*(-[a-z0-9]+)*\.md$', agent_file.name):
            self.frontmatter_issues.append({
                "severity": "warning",
                "location": self._get_relative_path(agent_file, scope),
                "issue": "Subagent filename should be lowercase-with-hyphens.md",
                "scope": scope
            })

        # Analyze classification
        self.analyze_subagent_classification(agent_file, frontmatter, content, scope)

    def parse_markdown(self, file_path: Path) -> tuple[Dict[str, Any], str]:
        """Parse YAML frontmatter and content from markdown file"""
        content = file_path.read_text(encoding="utf-8")

        # Extract frontmatter
        frontmatter = {}
        body = content

        if content.startswith("---"):
            parts = content.split("---", 2)
            if len(parts) >= 3:
                frontmatter_text = parts[1].strip()
                body = parts[2].strip()

                # Simple YAML parsing (sufficient for our needs)
                for line in frontmatter_text.split("\n"):
                    if ":" in line:
                        key, value = line.split(":", 1)
                        key = key.strip()
                        value = value.strip().strip('"').strip("'")

                        # Handle arrays
                        if value.startswith("[") and value.endswith("]"):
                            value = [v.strip().strip('"').strip("'") for v in value[1:-1].split(",")]

                        frontmatter[key] = value

        return frontmatter, body

    def validate_skill_frontmatter(self, frontmatter: Dict[str, Any], file_path: Path, scope: str):
        """Validate skill frontmatter fields"""
        required = ["name", "description"]
        optional = ["allowed-tools", "argument-hint", "disable-model-invocation",
                    "user-invocable", "model", "context", "agent", "hooks"]

        # Check required fields
        for field in required:
            if field not in frontmatter:
                self.frontmatter_issues.append({
                    "severity": "error",
                    "location": self._get_relative_path(file_path, scope),
                    "issue": f"Missing required frontmatter field: {field}",
                    "scope": scope
                })

        # Check description quality
        if "description" in frontmatter:
            desc = frontmatter["description"]
            if len(desc) < 50:
                self.frontmatter_issues.append({
                    "severity": "warning",
                    "location": self._get_relative_path(file_path, scope),
                    "issue": "Description too short (< 50 chars). Should include trigger conditions.",
                    "scope": scope
                })

    def validate_subagent_frontmatter(self, frontmatter: Dict[str, Any], file_path: Path, scope: str):
        """Validate subagent frontmatter fields"""
        required = ["name", "description"]

        # Check required fields
        for field in required:
            if field not in frontmatter:
                self.frontmatter_issues.append({
                    "severity": "error",
                    "location": self._get_relative_path(file_path, scope),
                    "issue": f"Missing required frontmatter field: {field}",
                    "scope": scope
                })

        # Check name format
        if "name" in frontmatter:
            name = frontmatter["name"]
            if not re.match(r'^[a-z][a-z0-9]*(-[a-z0-9]+)*$', name):
                self.frontmatter_issues.append({
                    "severity": "warning",
                    "location": self._get_relative_path(file_path, scope),
                    "issue": "Subagent name should be lowercase-with-hyphens",
                    "scope": scope
                })

    def check_skill_files(self, skill_dir: Path, scope: str):
        """Check for unnecessary files in skill directory"""
        unnecessary = ["README.md", "INSTALLATION_GUIDE.md", "QUICK_REFERENCE.md", "CHANGELOG.md"]

        for file in unnecessary:
            if (skill_dir / file).exists():
                self.file_issues.append({
                    "severity": "warning",
                    "location": self._get_relative_path(skill_dir / file, scope),
                    "issue": f"Unnecessary file: {file}. Skills should only contain AI-relevant files.",
                    "scope": scope
                })

    def analyze_skill_classification(self, skill_dir: Path, frontmatter: Dict[str, Any],
                                      content: str, scope: str):
        """Analyze if a skill should be a subagent"""
        reasons = []

        # Check for restricted tools
        if "allowed-tools" in frontmatter or "tools" in frontmatter:
            reasons.append("Uses restricted tool list (common for subagents)")

        # Check for Task tool usage
        if "Task" in content or "subagent" in content.lower():
            reasons.append("References Task tool or subagent delegation")

        # Check for workflow keywords
        workflow_count = sum(1 for signal in self.SUBAGENT_SIGNALS
                             if signal.lower() in content.lower())
        if workflow_count >= 3:
            reasons.append(f"Contains {workflow_count} workflow-related keywords")

        # Check content length
        line_count = len(content.split("\n"))
        if line_count > 800:
            reasons.append(f"Very long content ({line_count} lines) suggests complex workflow")

        # If significant reasons exist, flag as potential misclassification
        if len(reasons) >= 2:
            self.findings.append({
                "type": "potential_misclassification",
                "severity": "warning",
                "location": self._get_relative_path(skill_dir, scope),
                "current": "skill",
                "suggested": "subagent",
                "reasons": reasons,
                "recommendation": f"Consider moving to .claude/agents/{skill_dir.name}.md",
                "scope": scope
            })

    def analyze_subagent_classification(self, agent_file: Path, frontmatter: Dict[str, Any],
                                         content: str, scope: str):
        """Analyze if a subagent should be a skill"""
        reasons = []

        # Check if tools are unrestricted
        if "tools" not in frontmatter and "disallowedTools" not in frontmatter:
            reasons.append("No tool restrictions (common for skills)")

        # Check for skill keywords
        skill_count = sum(1 for signal in self.SKILL_SIGNALS
                          if signal.lower() in content.lower())
        if skill_count >= 3:
            reasons.append(f"Contains {skill_count} skill-related keywords")

        # Check if mainly reference content
        if "reference" in content.lower() and "## Reference" in content:
            reasons.append("Primarily provides reference knowledge")

        # Check content complexity
        line_count = len(content.split("\n"))
        if line_count < 100:
            reasons.append(f"Short content ({line_count} lines) suggests simple task")

        # If significant reasons exist, flag as potential misclassification
        if len(reasons) >= 2:
            agent_name = agent_file.stem
            self.findings.append({
                "type": "potential_misclassification",
                "severity": "info",
                "location": self._get_relative_path(agent_file, scope),
                "current": "subagent",
                "suggested": "skill",
                "reasons": reasons,
                "recommendation": f"Consider moving to .claude/skills/{agent_name}/SKILL.md",
                "scope": scope
            })

    def generate_report(self) -> Dict[str, Any]:
        """Generate inspection report"""
        return {
            "summary": {
                "total_skills": sum(1 for f in self.findings if ".claude/skills/" in f.get("location", "")),
                "total_subagents": sum(1 for f in self.findings if ".claude/agents/" in f.get("location", "")),
                "misclassified": len([f for f in self.findings if f["type"] == "potential_misclassification"]),
                "warnings": len([f for f in self.findings + self.structure_issues + self.frontmatter_issues + self.file_issues if f.get("severity") == "warning"]),
                "errors": len([f for f in self.structure_issues + self.frontmatter_issues if f.get("severity") == "error"])
            },
            "findings": self.findings,
            "structure_issues": self.structure_issues,
            "frontmatter_issues": self.frontmatter_issues,
            "file_issues": self.file_issues
        }


def main():
    parser = argparse.ArgumentParser(
        description="Inspect .claude/ directory structure and validate skills/subagents classification"
    )
    parser.add_argument(
        "--include-global",
        action="store_true",
        help="Also inspect global ~/.claude/ directory"
    )
    parser.add_argument(
        "--output",
        type=Path,
        help="Output report to JSON file"
    )
    parser.add_argument(
        "--base-dir",
        type=Path,
        default=Path.cwd(),
        help="Base directory (default: current directory)"
    )

    args = parser.parse_args()

    # Run inspection
    inspector = ClaudeInspector(args.base_dir, args.include_global)
    report = inspector.run()

    # Output report
    if args.output:
        args.output.write_text(json.dumps(report, indent=2, ensure_ascii=False))
        print(f"Report written to {args.output}")
    else:
        print(json.dumps(report, indent=2, ensure_ascii=False))

    # Exit with error code if issues found
    if report["summary"]["errors"] > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
