import React, { useState } from 'react';
import {
  TextField,
  Button,
  Grid,
  Box,
  Snackbar,
  Alert,
  Typography
} from '@mui/material';
import { DatePicker } from '@mui/x-date-pickers/DatePicker';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
import { Save } from '@mui/icons-material';
import { saveEmployee } from '../api';
import { useToast } from '../hooks/useToast';

export default function EmployeeForm() {
  const [form, setForm] = useState({
    firstName: '',
    lastName: '',
    email: '',
    departmentCode: '',
    position: '',
    salary: '',
    hireDate: null,
  });

  const toast = useToast();

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  const handleDateChange = (date: Date | null) => {
    setForm({ ...form, hireDate: date });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    try {
      const payload = {
        ...form,
        hireDate: form.hireDate ? form.hireDate.toISOString().split('T')[0] : null,
      };
      const res = await saveEmployee(payload);
      toast.showToast(`Employee saved with ID: ${res.data.id}`, 'success');
    } catch (err) {
      toast.showToast('Failed to save employee.', 'error');
    }
  };

  return (
    <LocalizationProvider dateAdapter={AdapterDateFns}>
      <Box component="form" onSubmit={handleSubmit} sx={{ mt: 2 }}>
        <Typography variant="subtitle1" gutterBottom>
          Fill in the employee details
        </Typography>

        <Grid container spacing={3}>
          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              variant="outlined"
              name="firstName"
              label="First Name"
              value={form.firstName}
              onChange={handleChange}
              required
              helperText="Enter employee's first name"
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              variant="outlined"
              name="lastName"
              label="Last Name"
              value={form.lastName}
              onChange={handleChange}
              required
              helperText="Enter employee's last name"
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              variant="outlined"
              name="email"
              label="Email"
              type="email"
              value={form.email}
              onChange={handleChange}
              required
              helperText="Employee's email address"
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              variant="outlined"
              name="departmentCode"
              label="Department Code"
              value={form.departmentCode}
              onChange={handleChange}
              required
              helperText="e.g., DEP001"
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              variant="outlined"
              name="position"
              label="Position"
              value={form.position}
              onChange={handleChange}
              helperText="Optional - Job title"
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              variant="outlined"
              name="salary"
              label="Salary"
              type="number"
              value={form.salary}
              onChange={handleChange}
              helperText="Optional - Gross salary"
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <DatePicker
              label="Hire Date"
              value={form.hireDate}
              onChange={handleDateChange}
              renderInput={(params) => (
                <TextField {...params} fullWidth required helperText="Date of hiring" />
              )}
            />
          </Grid>

          <Grid item xs={12}>
            <Button
              type="submit"
              variant="contained"
              color="primary"
              size="large"
              startIcon={<Save />}
              sx={{ mt: 1 }}
            >
              Save Employee
            </Button>
          </Grid>
        </Grid>

        <Snackbar
          open={toast.open}
          autoHideDuration={3000}
          onClose={toast.handleClose}
          anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
        >
          <Alert onClose={toast.handleClose} severity={toast.severity} sx={{ width: '100%' }}>
            {toast.message}
          </Alert>
        </Snackbar>
      </Box>
    </LocalizationProvider>
  );
}
