"""SQL guard tests.

The analytical path executes model-written SQL, so these are security tests, not
correctness tests. Each case is an attack the guard must refuse.
"""

import pytest

from app.services.sql_guard import UnsafeSQL, validate


class TestAllowed:
    def test_simple_select(self):
        out = validate("select agent_name, avg_score from v_agent_scorecard")
        assert out.startswith("select")
        assert "limit 200" in out

    def test_cte_is_allowed(self):
        out = validate(
            "with recent as (select * from v_call_overview limit 10) select count(*) from recent"
        )
        assert "recent" in out

    def test_trailing_semicolon_is_tolerated(self):
        assert validate("select 1 from calls;").startswith("select")

    def test_existing_limit_is_kept_when_reasonable(self):
        assert validate("select * from calls limit 5").endswith("limit 5")

    def test_oversized_limit_is_capped(self):
        assert validate("select * from calls limit 100000").endswith("limit 200")


class TestBlocked:
    @pytest.mark.parametrize(
        "sql",
        [
            "drop table calls",
            "delete from calls",
            "update calls set status = 'x'",
            "insert into calls (call_code) values ('x')",
            "truncate calls",
            "alter table calls add column x int",
            "grant all on calls to public",
        ],
    )
    def test_destructive_statements_refused(self, sql):
        with pytest.raises(UnsafeSQL):
            validate(sql)

    def test_stacked_statement_refused(self):
        """The classic injection: a valid query followed by a destructive one."""
        with pytest.raises(UnsafeSQL, match="single statement"):
            validate("select 1 from calls; drop table calls")

    def test_comment_smuggled_statement_refused(self):
        """Comments are stripped BEFORE the semicolon check, so hiding the
        second statement behind a comment marker does not help."""
        with pytest.raises(UnsafeSQL):
            validate("select 1 from calls /* x */ ; drop table calls")

    def test_non_whitelisted_relation_refused(self):
        with pytest.raises(UnsafeSQL, match="not available"):
            validate("select * from profiles")

    def test_chat_history_is_not_reachable(self):
        """A manager's questions to the assistant are private, including from
        the assistant itself."""
        with pytest.raises(UnsafeSQL, match="not available"):
            validate("select content from chat_messages")

    def test_auth_schema_is_not_reachable(self):
        with pytest.raises(UnsafeSQL):
            validate("select * from auth.users")

    def test_denial_of_service_function_refused(self):
        with pytest.raises(UnsafeSQL, match="function"):
            validate("select pg_sleep(60) from calls")

    def test_file_read_function_refused(self):
        with pytest.raises(UnsafeSQL, match="function"):
            validate("select pg_read_file('/etc/passwd') from calls")

    def test_non_select_refused(self):
        with pytest.raises(UnsafeSQL, match="SELECT"):
            validate("explain analyze select 1")

    def test_empty_refused(self):
        with pytest.raises(UnsafeSQL):
            validate("   ")

    def test_join_to_forbidden_relation_refused(self):
        """A whitelisted FROM does not launder a forbidden JOIN."""
        with pytest.raises(UnsafeSQL, match="not available"):
            validate("select * from calls join profiles on true")
