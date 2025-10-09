import os
from locust import HttpUser, task, between


SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_ANON_KEY = os.environ.get("SUPABASE_ANON_KEY")


def _ensure_config():
    if not SUPABASE_URL or not SUPABASE_ANON_KEY:
        raise RuntimeError(
            "SUPABASE_URL e SUPABASE_ANON_KEY devono essere impostate prima di avviare Locust."
        )


class SupabaseHonooUser(HttpUser):
    wait_time = between(1, 3)

    def on_start(self):
        _ensure_config()
        self.client.headers.update(
            {
                "apikey": SUPABASE_ANON_KEY,
                "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
                "Accept": "application/json",
            }
        )

    @task(3)
    def fetch_moon_honoo(self):
        params = {
            "destination": "eq.moon",
            "select": "id,text,image_url,created_at",
            "order": "created_at.desc",
            "limit": "20",
        }
        self.client.get(
            f"{SUPABASE_URL}/rest/v1/honoo",
            params=params,
            name="GET /honoo moon",
        )

    @task(2)
    def fetch_chest_honoo(self):
        user_id = os.environ.get(
            "LOADTEST_USER_ID", "00000000-0000-0000-0000-000000000000"
        )
        params = {
            "destination": "eq.chest",
            "user_id": f"eq.{user_id}",
            "select": "id,text,image_url,created_at",
            "order": "created_at.desc",
            "limit": "20",
        }
        self.client.get(
            f"{SUPABASE_URL}/rest/v1/honoo",
            params=params,
            name="GET /honoo chest",
        )

    @task(1)
    def fetch_hinoo_moon(self):
        params = {
            "type": "eq.moon",
            "select": "id,pages,recipient_tag,created_at",
            "order": "created_at.desc",
            "limit": "20",
        }
        self.client.get(
            f"{SUPABASE_URL}/rest/v1/hinoo",
            params=params,
            name="GET /hinoo moon",
        )


class SupabaseBurstUser(SupabaseHonooUser):
    wait_time = between(0.2, 0.8)

    @task(4)
    def fetch_public_honoo_cursor(self):
        params = {
            "destination": "eq.moon",
            "select": "id,text,created_at",
            "order": "created_at.desc",
            "limit": "20",
            "created_at": "lt." + os.environ.get("LOADTEST_BEFORE", "3000-01-01T00:00:00Z"),
        }
        self.client.get(
            f"{SUPABASE_URL}/rest/v1/honoo",
            params=params,
            name="GET /honoo moon (cursor)",
        )
