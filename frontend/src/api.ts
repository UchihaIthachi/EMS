import axios from 'axios';

const BASE_URL = 'http://localhost:8080/api/v1';

const EMPLOYEE_BASE = `${BASE_URL}/employee-service`;
const DEPARTMENT_BASE = `${BASE_URL}/department-controller`;

export const saveEmployee = (data: any) =>
  axios.post(`${EMPLOYEE_BASE}/`, data);

export const getEmployee = (id: string) =>
  axios.get(`${EMPLOYEE_BASE}/${id}`);

export const getEmployeeMessage = () =>
  axios.get(`${EMPLOYEE_BASE}/users/message`, { responseType: 'text' });

export const getDepartmentMessage = () =>
  axios.get(`${DEPARTMENT_BASE}/message`, { responseType: 'text' });
