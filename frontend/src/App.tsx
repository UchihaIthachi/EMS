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
// import Navbar from './components/Navbar'; // Will be removed
import Footer from './components/Footer';
import LandingPage from './components/LandingPage';
import SaveDepartmentPage from './components/SaveDepartmentPage';
import FindDepartmentPage from './components/FindDepartmentPage';
import MainLayout from './components/MainLayout'; // Added
import { getEmployeeMessage, getDepartmentMessage } from './api';
import { useToast } from './hooks/useToast';

const theme = createTheme({
  palette: {
    mode: 'light', // Or 'dark'
    primary: {
      main: '#1976d2', // Example primary color
    },
    background: {
      default: '#f5f7fa', // A light grey background
    },
  },
  typography: {
    fontFamily: 'Roboto, sans-serif',
  },
  // Spacing, breakpoints, etc., can be customized here
});

export default function App() {
  const [empMsg, setEmpMsg] = useState('');
  const [deptMsg, setDeptMsg] = useState('');
  const toast = useToast();

  useEffect(() => {
    // Fetch messages, handling potential errors
    getEmployeeMessage().then(res => setEmpMsg(res.data)).catch(err => console.error("Failed to fetch employee message:", err));
    getDepartmentMessage().then(res => setDeptMsg(res.data)).catch(err => console.error("Failed to fetch department message:", err));
  }, []);

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline /> {/* Ensures baseline styling and applies background from theme */}
      <Box sx={{ display: 'flex', flexDirection: 'column', minHeight: '100vh' }}>
        <MainLayout> {/* MainLayout now wraps the routes and provides AppBar/Drawer */}
          {/* The main content Box in MainLayout already has p:3. Container here is for maxWidth and centering. */}
          <Container component="div" maxWidth="lg" sx={{ mb: 4, flexGrow: 1 }}> {/* Removed mt: 2 */}
            <Routes>
              <Route path="/" element={<LandingPage />} />
              <Route
                path="/create-employee"
                element={
                  // Pages using Paper should have their own consistent padding.
                  <Paper elevation={3} sx={{ p: 3, mb: 3 }}>
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
                  <Paper elevation={3} sx={{ p: 3, mb: 3 }}> {/* Adjusted padding/margin slightly */}
                    <Typography variant="h6" color="primary" gutterBottom>
                      🔍 Lookup Employee by ID
                    </Typography>
                    <Divider sx={{ mb: 2 }} />
                    <EmployeeDetails toast={toast} />
                  </Paper>
                }
              />
              {/* SaveDepartmentPage and FindDepartmentPage already use Container and Paper internally */}
              <Route path="/create-department" element={<SaveDepartmentPage />} />
              <Route path="/department-details" element={<FindDepartmentPage />} />
              <Route
                path="/messages"
                element={
                  <Paper elevation={3} sx={{ p: 3 }}> {/* Adjusted padding slightly */}
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
        </MainLayout>
        <Footer /> {/* Footer remains outside MainLayout for sticky behavior if desired */}
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
