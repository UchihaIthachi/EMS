import React, { useEffect, useState } from 'react';
import { Routes, Route } from 'react-router-dom';
import {
  Container,
  Typography,
  Divider,
  Box,
  CssBaseline,
  ThemeProvider,
  createTheme,
  Paper,
  Snackbar,
  Alert,
} from '@mui/material';

import EmployeeForm from './components/EmployeeForm';
import EmployeeDetails from './components/EmployeeDetails';
import Navbar from './components/Navbar';
import Footer from './components/Footer';
import LandingPage from './components/LandingPage';
import SaveDepartmentPage from './components/SaveDepartmentPage'; // Added
import FindDepartmentPage from './components/FindDepartmentPage'; // Added
import { getEmployeeMessage, getDepartmentMessage } from './api';
import { useToast } from './hooks/useToast';

const theme = createTheme({
  palette: {
    mode: 'light',
    primary: {
      main: '#1976d2',
    },
    background: {
      default: '#f5f7fa',
    },
  },
  typography: {
    fontFamily: 'Roboto, sans-serif',
  },
});

export default function App() {
  const [empMsg, setEmpMsg] = useState('');
  const [deptMsg, setDeptMsg] = useState('');
  const toast = useToast();

  useEffect(() => {
    getEmployeeMessage().then(res => setEmpMsg(res.data));
    getDepartmentMessage().then(res => setDeptMsg(res.data));
  }, []);

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Box sx={{ display: 'flex', flexDirection: 'column', minHeight: '100vh' }}>
        <Navbar />
        <Container component="main" maxWidth="md" sx={{ mt: 5, mb: 5, flexGrow: 1 }}>
          <Routes>
            <Route path="/" element={<LandingPage />} />
            <Route
              path="/create-employee"
              element={
                <Paper elevation={3} sx={{ p: 4, mb: 4 }}>
                  <Typography variant="h6" color="primary" gutterBottom>
                    ➕ Create Employee
                  </Typography>
                  <Divider sx={{ mb: 2 }} />
                  <EmployeeForm toast={toast} />
                </Paper>
              }
            />
            <Route
              path="/employee-details"
              element={
                <Paper elevation={3} sx={{ p: 4, mb: 4 }}>
                  <Typography variant="h6" color="primary" gutterBottom>
                    🔍 Lookup Employee by ID
                  </Typography>
                  <Divider sx={{ mb: 2 }} />
                  <EmployeeDetails toast={toast} />
                </Paper>
              }
            />
            <Route path="/create-department" element={<SaveDepartmentPage />} />
            <Route path="/department-details" element={<FindDepartmentPage />} />
            <Route
              path="/messages"
              element={
                <Paper elevation={3} sx={{ p: 4 }}>
                  <Typography variant="h6" color="primary" gutterBottom>
                    ℹ️ Service Messages
                  </Typography>
                  <Divider sx={{ mb: 2 }} />
                  <Typography sx={{ mt: 1 }}><strong>Employee:</strong> {empMsg}</Typography>
                  <Typography><strong>Department:</strong> {deptMsg}</Typography>
                </Paper>
              }
            />
          </Routes>
        </Container>
        <Footer />
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
    </ThemeProvider>
  );
}
