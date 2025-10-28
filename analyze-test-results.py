#!/usr/bin/env python3

"""
Analyze migration test results
Processes logs from test-migration.sh and generates insights
"""

import json
import sys
import os
import re
from pathlib import Path
from datetime import datetime
from collections import defaultdict

class TestAnalyzer:
    def __init__(self, log_file):
        self.log_file = log_file
        self.results = defaultdict(list)
        self.errors = []
        self.warnings = []
        self.stats = {
            'total_tests': 0,
            'passed': 0,
            'failed': 0,
            'timeout': 0,
            'skipped': 0,
            'total_duration': 0
        }
        self.package_results = defaultdict(dict)
        self.build_times = {}

    def parse_log(self):
        """Parse test log file"""
        if not os.path.exists(self.log_file):
            print(f"❌ Log file not found: {self.log_file}")
            return False

        try:
            with open(self.log_file, 'r') as f:
                lines = f.readlines()

            for line in lines:
                # Parse test results
                if '[RESULT]' in line:
                    self.parse_result_line(line)
                elif '[ERROR]' in line:
                    self.errors.append(line.strip())
                elif '[WARN]' in line:
                    self.warnings.append(line.strip())

            return True
        except Exception as e:
            print(f"❌ Error parsing log: {e}")
            return False

    def parse_result_line(self, line):
        """Parse a result line"""
        # Example: [2025-01-01 12:00:00] [RESULT] Test Name: PASS (120s)
        match = re.search(r'\[RESULT\]\s+(.+?):\s+(PASS|FAIL|SKIP|TIMEOUT)\s+\((\d+)s\)', line)
        if match:
            test_name = match.group(1)
            status = match.group(2)
            duration = int(match.group(3))

            self.results[status].append({
                'name': test_name,
                'duration': duration
            })

            # Update stats
            self.stats['total_tests'] += 1
            if status == 'PASS':
                self.stats['passed'] += 1
            elif status == 'FAIL':
                self.stats['failed'] += 1
            elif status == 'TIMEOUT':
                self.stats['timeout'] += 1
            elif status == 'SKIP':
                self.stats['skipped'] += 1

            self.stats['total_duration'] += duration

            # Track build times
            self.build_times[test_name] = duration

    def categorize_tests(self):
        """Categorize tests by type"""
        categories = defaultdict(list)

        for test_name in self.build_times.keys():
            if 'Rust' in test_name or 'microcosm' in test_name:
                categories['Rust'].append(test_name)
            elif 'Go' in test_name or 'tangled' in test_name:
                categories['Go'].append(test_name)
            elif 'Node' in test_name or 'npm' in test_name or 'npm' in test_name:
                categories['Node.js'].append(test_name)
            elif 'Deno' in test_name or 'pds-dash' in test_name:
                categories['Deno'].append(test_name)
            elif 'Architecture' in test_name or 'Structure' in test_name:
                categories['Architecture'].append(test_name)
            elif 'Flake' in test_name:
                categories['Flake'].append(test_name)
            elif 'Fix' in test_name or 'Critical' in test_name:
                categories['Critical Fixes'].append(test_name)
            elif 'Validation' in test_name or 'Quality' in test_name:
                categories['Code Quality'].append(test_name)
            else:
                categories['Other'].append(test_name)

        return categories

    def generate_report(self, output_file=None):
        """Generate comprehensive analysis report"""
        report = []

        # Header
        report.append("╔════════════════════════════════════════════════════════════════╗")
        report.append("║   Migration Test Results - Comprehensive Analysis Report       ║")
        report.append("╚════════════════════════════════════════════════════════════════╝")
        report.append("")

        # Timestamp
        report.append(f"Report generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        report.append(f"Log file: {self.log_file}")
        report.append("")

        # Summary Statistics
        report.append("📊 SUMMARY STATISTICS")
        report.append("=" * 60)
        pass_rate = (self.stats['passed'] / self.stats['total_tests'] * 100) if self.stats['total_tests'] > 0 else 0
        fail_rate = (self.stats['failed'] / self.stats['total_tests'] * 100) if self.stats['total_tests'] > 0 else 0

        report.append(f"  Total Tests:     {self.stats['total_tests']}")
        report.append(f"  ✓ Passed:        {self.stats['passed']} ({pass_rate:.1f}%)")
        report.append(f"  ✗ Failed:        {self.stats['failed']} ({fail_rate:.1f}%)")
        report.append(f"  ⏱ Timeout:       {self.stats['timeout']}")
        report.append(f"  ⊘ Skipped:       {self.stats['skipped']}")
        report.append(f"  ⏱ Total Duration: {self.stats['total_duration']}s (~{self.stats['total_duration'] // 60}m)")
        report.append("")

        # Detailed Results by Category
        categories = self.categorize_tests()
        report.append("📋 RESULTS BY CATEGORY")
        report.append("=" * 60)

        for category in sorted(categories.keys()):
            tests = categories[category]
            report.append(f"\n{category}:")
            report.append("-" * 40)

            for test_name in sorted(tests):
                status = "UNKNOWN"
                for s, test_list in self.results.items():
                    if any(t['name'] == test_name for t in test_list):
                        status = s
                        break

                duration = self.build_times.get(test_name, 0)
                status_icon = {'PASS': '✓', 'FAIL': '✗', 'TIMEOUT': '⏱', 'SKIP': '⊘'}.get(status, '?')

                report.append(f"  {status_icon} {test_name:<45} {status:<8} ({duration}s)")

        # Performance Analysis
        report.append("\n")
        report.append("⚡ PERFORMANCE ANALYSIS")
        report.append("=" * 60)

        # Slowest tests
        slowest = sorted(self.build_times.items(), key=lambda x: x[1], reverse=True)[:5]
        report.append("\nSlowest 5 Tests:")
        for test_name, duration in slowest:
            report.append(f"  {duration:>4}s  {test_name}")

        # Average times by category
        report.append("\nAverage Times by Category:")
        for category in sorted(categories.keys()):
            tests = categories[category]
            durations = [self.build_times.get(t, 0) for t in tests]
            avg_duration = sum(durations) / len(durations) if durations else 0
            report.append(f"  {category:<15}  {avg_duration:>6.1f}s avg ({sum(durations)}s total)")

        # Error Analysis
        if self.errors:
            report.append("\n")
            report.append("❌ ERRORS")
            report.append("=" * 60)
            report.extend(self.errors[:10])  # Limit to first 10
            if len(self.errors) > 10:
                report.append(f"... and {len(self.errors) - 10} more errors")

        # Warning Analysis
        if self.warnings:
            report.append("\n")
            report.append("⚠️  WARNINGS")
            report.append("=" * 60)
            report.extend(self.warnings[:10])  # Limit to first 10
            if len(self.warnings) > 10:
                report.append(f"... and {len(self.warnings) - 10} more warnings")

        # Recommendations
        report.append("\n")
        report.append("📝 RECOMMENDATIONS")
        report.append("=" * 60)

        if self.stats['failed'] == 0 and self.stats['timeout'] == 0:
            report.append("✅ All tests passed! Migration is successful.")
            report.append("   Next steps:")
            report.append("   1. Review the detailed test log for any warnings")
            report.append("   2. Commit migration with confidence")
            report.append("   3. Update CLAUDE.md to reference new lib/packaging")
        else:
            report.append("❌ Some tests failed or timed out.")
            report.append("   Next steps:")
            report.append("   1. Review failed tests in detailed log")
            report.append("   2. Identify patterns (language-specific? platform-specific?)")
            report.append("   3. Fix critical issues first")
            report.append("   4. Re-run test suite")

        # Final status
        report.append("")
        report.append("=" * 60)
        if self.stats['failed'] == 0 and self.stats['timeout'] == 0:
            report.append("✓ OVERALL STATUS: PASS")
        else:
            report.append("✗ OVERALL STATUS: FAIL")
        report.append("=" * 60)

        # Print and save
        report_text = "\n".join(report)
        print(report_text)

        if output_file:
            try:
                with open(output_file, 'w') as f:
                    f.write(report_text)
                print(f"\n💾 Report saved to: {output_file}")
            except Exception as e:
                print(f"⚠️  Could not save report: {e}")

        return report_text

    def export_json(self, output_file):
        """Export results as JSON"""
        data = {
            'timestamp': datetime.now().isoformat(),
            'stats': self.stats,
            'results_by_status': {
                'passed': self.results['PASS'],
                'failed': self.results['FAIL'],
                'timeout': self.results['TIMEOUT'],
                'skipped': self.results['SKIP']
            },
            'build_times': self.build_times,
            'errors': self.errors,
            'warnings': self.warnings
        }

        try:
            with open(output_file, 'w') as f:
                json.dump(data, f, indent=2)
            print(f"✓ JSON results exported to: {output_file}")
        except Exception as e:
            print(f"✗ Could not export JSON: {e}")

def main():
    # Find latest test log
    log_dir = Path("test-results")
    if not log_dir.exists():
        print("❌ test-results directory not found")
        print("   Run: ./test-migration.sh first")
        sys.exit(1)

    # Get latest log file
    log_files = sorted(log_dir.glob("test-results-*.log"))
    if not log_files:
        print("❌ No test log files found")
        sys.exit(1)

    log_file = str(log_files[-1])
    print(f"📂 Analyzing log: {log_file}")
    print()

    # Analyze
    analyzer = TestAnalyzer(log_file)
    if not analyzer.parse_log():
        sys.exit(1)

    # Generate report
    report_file = log_dir / "analysis-report.txt"
    analyzer.generate_report(str(report_file))

    # Export JSON
    json_file = log_dir / "results.json"
    analyzer.export_json(str(json_file))

    # Return appropriate exit code
    sys.exit(0 if analyzer.stats['failed'] == 0 and analyzer.stats['timeout'] == 0 else 1)

if __name__ == "__main__":
    main()
