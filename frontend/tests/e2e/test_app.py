import pytest
from playwright.sync_api import Page, expect

def test_app_functionality(page: Page):
    """
    Tests the complete application flow:
    1. Loads the page and checks service messages.
    2. Creates a new employee (POST).
    3. Looks up an existing employee (GET).
    """

    # 1. Mock Service Status Messages
    page.route("**/employee-service/api/v1/employee-service/users/message", lambda route: route.fulfill(
        status=200,
        content_type="text/plain",
        body="Employee Service is UP"
    ))
    
    page.route("**/department-service/api/v1/department-service/message", lambda route: route.fulfill(
        status=200,
        content_type="text/plain",
        body="Department Service is UP"
    ))
    
    # 2. Mock Create Employee API (POST)
    page.route("**/employee-service/api/v1/employee-service/", lambda route: route.fulfill(
        status=201,
        content_type="application/json",
        body='{"id": 123, "firstName": "Alice", "lastName": "Wonder", "email": "alice@example.com"}'
    ))

    # 3. Mock Get Employee API (GET)
    page.route("**/employee-service/api/v1/employee-service/123", lambda route: route.fulfill(
        status=200,
        content_type="application/json",
        body='{"id": 123, "firstName": "Alice", "lastName": "Wonder", "email": "alice@example.com", "departmentCode": "D001"}'
    ))

    # --- Start Test Execution ---

    # Go to app
    page.goto("http://localhost:3001/")
    
    # Check title
    expect(page).to_have_title("Vite + React + TS")
    
    # Verify service messages are displayed
    expect(page.get_by_text("Employee Service is UP")).to_be_visible()
    expect(page.get_by_text("Department Service is UP")).to_be_visible()
    
    page.screenshot(path="frontend/tests/e2e/screenshots/1_homepage_loaded.png")

    # --- Test "Create Employee" Form ---
    page.get_by_label("First Name").fill("Alice")
    page.get_by_label("Last Name").fill("Wonder")
    page.get_by_label("Email").fill("alice@example.com")
    page.get_by_label("Department Code").fill("D001")
    
    # Hire Date handling: click and type
    page.get_by_label("Hire Date").first.click()
    page.keyboard.type("01012023") 
    
    # Click Submit
    page.get_by_role("button", name="Save Employee").click()
    
    # Verify success toast
    expect(page.get_by_text("Employee saved with ID: 123")).to_be_visible()
    
    page.screenshot(path="frontend/tests/e2e/screenshots/2_employee_created.png")

    # --- Test "Lookup Employee" Form ---
    # Input ID
    page.get_by_label("Employee ID").fill("123")
    
    # Click Fetch
    page.get_by_role("button", name="Fetch").click()
    
    # Verify success toast
    expect(page.get_by_text("Employee data loaded successfully!")).to_be_visible()
    
    # Verify JSON output contains the name "Alice" and "Wonder"
    expect(page.get_by_text('"firstName": "Alice"')).to_be_visible()
    expect(page.get_by_text('"lastName": "Wonder"')).to_be_visible()
    
    page.screenshot(path="frontend/tests/e2e/screenshots/3_employee_lookup.png")
