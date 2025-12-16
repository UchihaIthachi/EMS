import pytest
import re
from playwright.sync_api import Page, expect

def test_zipkin_loads(page: Page):
    try:
        page.goto("http://localhost:9411/zipkin/", timeout=30000)
        expect(page).to_have_title("Zipkin")
        page.screenshot(path="frontend/tests/e2e/screenshots/zipkin_dashboard.png")
    except Exception as e:
        pytest.fail(f"Zipkin failed to load: {e}")

def test_grafana_loads(page: Page):
    try:
        # Grafana might take a while to start
        page.goto("http://localhost:3000/login", timeout=60000)
        # Check for title "Grafana" using regex
        expect(page).to_have_title(re.compile("Grafana"))
        page.screenshot(path="frontend/tests/e2e/screenshots/grafana_login.png")
    except Exception as e:
        pytest.fail(f"Grafana failed to load: {e}")
