import axios from "axios";

// const BASE_URL = "http://api-gateway:9191/api/v1";
const BASE_URL = "/api/v1";

const EMPLOYEE_BASE = `/employee-service/api/v1/employee-service`;
const DEPARTMENT_BASE = `/department-service/api/v1/department-service`;

export const saveEmployee = (data: any) =>
  axios.post(`${EMPLOYEE_BASE}/`, data);

export const getEmployee = (id: string) => axios.get(`${EMPLOYEE_BASE}/${id}`);

export const getEmployeeMessage = () =>
  axios.get(`${EMPLOYEE_BASE}/users/message`, { responseType: "text" });

export const getDepartmentMessage = () =>
  axios.get(`${DEPARTMENT_BASE}/message`, { responseType: "text" });

export const saveDepartment = (data: any) =>
  axios.post(`${DEPARTMENT_BASE}/`, data);

export const getDepartmentByCode = (code: string) =>
  axios.get(`${DEPARTMENT_BASE}/${code}`);
