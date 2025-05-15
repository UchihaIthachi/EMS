
## 📄 **API Documentation**

### 📌 **Employee Service APIs**

**Base URL:**

```
http://<host>:8084/api/v1/employee-service
```

---

### 🔸 **Save Employee**

* **URL:** `/`
* **Method:** `POST`
* **Description:** Creates a new employee.
* **Request Body:**

```json
{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john.doe@example.com",
  "departmentCode": "DEP001",
  "position": "Software Engineer",
  "salary": 75000.00,
  "hireDate": "2022-01-15"
}
```

* **Response:** `201 Created`

```json
{
  "id": 1,
  "firstName": "John",
  "lastName": "Doe",
  "email": "john.doe@example.com",
  "departmentCode": "DEP001",
  "position": "Software Engineer",
  "salary": 75000.0,
  "hireDate": "2022-01-15"
}
```

---

### 🔸 **Get Employee by ID (With Department Details)**

* **URL:** `/{id}`
* **Method:** `GET`
* **Description:** Retrieves employee details along with the related department information.
* **Response:** `200 OK`

```json
{
  "employee": {
    "id": 1,
    "firstName": "John",
    "lastName": "Doe",
    "email": "john.doe@example.com",
    "departmentCode": "DEP001",
    "position": "Software Engineer",
    "salary": 75000.0,
    "hireDate": "2022-01-15"
  },
  "department": {
    "id": 1,
    "departmentName": "IT",
    "departmentDescription": "Information Technology",
    "departmentCode": "DEP001"
  }
}
```

---

### 🔸 **Get Employee Service Message**

* **URL:** `/users/message`
* **Method:** `GET`
* **Description:** Retrieves a configurable message from the employee service (loaded via Config Server).
* **Response:** `200 OK`

```text
This is a sample message from Employee Service.
```

---

### 📌 **Department Service APIs**

**Base URL:**

```
http://<host>:8083/api/v1/department-controller
```

---

### 🔹 **Save Department**

* **URL:** `/`
* **Method:** `POST`
* **Description:** Creates a new department.
* **Request Body:**

```json
{
  "departmentName": "IT",
  "departmentDescription": "Information Technology",
  "departmentCode": "DEP001"
}
```

* **Response:** `201 Created`

```json
{
  "id": 1,
  "departmentName": "IT",
  "departmentDescription": "Information Technology",
  "departmentCode": "DEP001"
}
```

---

### 🔹 **Find Department by Code**

* **URL:** `/{department-code}`
* **Method:** `GET`
* **Description:** Retrieves department details by department code.
* **Response:** `200 OK`

```json
{
  "id": 1,
  "departmentName": "IT",
  "departmentDescription": "Information Technology",
  "departmentCode": "DEP001"
}
```

---

### 🔹 **Get Department Service Message**

* **URL:** `/message`
* **Method:** `GET`
* **Description:** Retrieves a configurable message from the department service (loaded via Config Server).
* **Response:** `200 OK`

```text
This is a sample message from Department Service.
```

---

## 📝 **Entity Definitions**

### 🔸 **Employee Entity**

| Field            | Type    | Constraints         |
| ---------------- | ------- | ------------------- |
| `id`             | Long    | Auto-generated (PK) |
| `firstName`      | String  |                     |
| `lastName`       | String  |                     |
| `email`          | String  | Unique, Not Null    |
| `departmentCode` | String  |                     |
| `position`       | String  | Optional            |
| `salary`         | Decimal | Optional            |
| `hireDate`       | Date    | Optional            |

---

### 🔹 **Department Entity**

| Field                   | Type    | Constraints         |
| ----------------------- | ------- | ------------------- |
| `id`                    | Integer | Auto-generated (PK) |
| `departmentName`        | String  |                     |
| `departmentDescription` | String  |                     |
| `departmentCode`        | String  | Unique, Not Null    |

---

## ⚙️ **Configuration Endpoints**

Endpoints that return dynamic configuration messages from the Spring Cloud Config Server:

| Service            | Endpoint         | Method |
| ------------------ | ---------------- | ------ |
| Employee Service   | `/users/message` | GET    |
| Department Service | `/message`       | GET    |

---

### ✅ **HTTP Status Codes**

| Status Code        | Description            |
| ------------------ | ---------------------- |
| `200 OK`           | Successful retrieval   |
| `201 Created`      | Successfully created   |
| `400 Bad Request`  | Invalid request format |
| `404 Not Found`    | Resource not found     |
| `500 Server Error` | Internal server error  |

---
