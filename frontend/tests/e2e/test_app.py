
import re
from playwright.sync_api import Page, expect, sync_playwright

def test_ui_flow(page: Page):
    # Mock API responses
    # Note: the frontend calls `/employee-service/api/v1/employee-service/` (relative)
    # which Vite proxies or fails to find.
    # The actual code in api.ts is:
    # const EMPLOYEE_BASE = `/employee-service/api/v1/employee-service`;
    # axios.post(`${EMPLOYEE_BASE}/`, data);
    # So the URL is `/employee-service/api/v1/employee-service/`
    
    # We need to route this pattern.
    
    # 1. Mock creating a department (if used)
    page.route("**/department-service/api/v1/department-service", lambda route: route.fulfill(
        status=201,
        content_type="application/json",
        body='{"id":1,"departmentName":"IT","departmentDescription":"Tech Team","departmentCode":"IT001"}'
    ))

    # 2. Mock creating an employee
    # Match any POST to the employee service
    page.route("**/employee-service/api/v1/employee-service/", lambda route: route.fulfill(
        status=201,
        content_type="application/json",
        body='{"id":1,"firstName":"Jane","lastName":"Doe","email":"jane@test.com","departmentCode":"IT001"}'
    ))
    
    # Also catch without trailing slash just in case
    page.route("**/employee-service/api/v1/employee-service", lambda route: route.fulfill(
        status=201,
        content_type="application/json",
        body='{"id":1,"firstName":"Jane","lastName":"Doe","email":"jane@test.com","departmentCode":"IT001"}'
    ))

    # 3. Mock getting all employees (if list view exists)
    # page.route("**/employee-service/api/v1/employee-service", lambda route: route.fulfill(...))

    # 4. Mock getting a single employee with department (for view details)
    page.route("**/employee-service/api/v1/employee-service/1", lambda route: route.fulfill(
        status=200,
        content_type="application/json",
        body='{"employee":{"id":1,"firstName":"Jane","lastName":"Doe","email":"jane@test.com","departmentCode":"IT001"},"department":{"id":1,"departmentName":"IT","departmentDescription":"Tech Team","departmentCode":"IT001"}}'
    ))

    # Mock message endpoints to avoid 404s in console
    page.route("**/users/message", lambda route: route.fulfill(status=200, body="Employee Service Online"))
    page.route("**/department-service/message", lambda route: route.fulfill(status=200, body="Department Service Online"))


    base_url = "http://localhost:5173"
    print(f"Navigating to {base_url}")
    page.goto(base_url)

    print("Waiting for 'Employee Service Portal'")
    expect(page.get_by_text("Employee Service Portal")).to_be_visible()

    print("Filling Employee Form")
    page.get_by_label("First Name").fill("Jane")
    page.get_by_label("Last Name").fill("Doe")
    page.get_by_label("Email").fill("jane@test.com")
    page.get_by_label("Department Code").fill("IT001")
    
    print("Filling Hire Date")
    page.get_by_label("Hire Date").locator("input").first.fill("01/01/2023", force=True)

    print("Submitting Employee Form")
    save_button = page.get_by_role("button", name="Save Employee")
    save_button.click()
    
    print("Verifying Success Toast")
    expect(page.get_by_text("Employee saved with ID: 1")).to_be_visible(timeout=10000)
    
    print("Looking up Employee")
    page.get_by_label("Employee ID").fill("1")
    page.get_by_role("button", name="Fetch").click()
    
    print("Verifying Employee Details")
    expect(page.get_by_text("Employee data loaded successfully!")).to_be_visible(timeout=10000)
    expect(page.get_by_text('"firstName": "Jane"')).to_be_visible()
    expect(page.get_by_text('"departmentName": "IT"')).to_be_visible()

    screenshot_path = "frontend/tests/e2e/ui_test_result.png"
    page.screenshot(path=screenshot_path)
    print(f"Test passed and screenshot taken at {screenshot_path}")

if __name__ == "__main__":
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.on("console", lambda msg: print(f"Browser Console: {msg.text}"))
        try:
            test_ui_flow(page)
        except Exception as e:
            print(f"Test failed: {e}")
            page.screenshot(path="frontend/tests/e2e/ui_test_failure.png")
        finally:
            browser.close()
