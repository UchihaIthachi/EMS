import React from 'react';
import { Typography, Container, Paper, Box } from '@mui/material';

const LandingPage: React.FC = () => {
  return (
    // Removed mt: 5, MainLayout's padding and AppBar spacing should be sufficient.
    // mb: 5 can remain if specific bottom spacing for this page is desired, or be standardized.
    // For consistency, let's use mb: 3 or mb: 4 like other Paper/Container elements.
    <Container maxWidth="md" sx={{ mb: 4 }}>
      <Paper elevation={3} sx={{ p: 4 }}>
        <Typography variant="h4" component="h1" gutterBottom>
          Welcome to the Employee Portal
        </Typography>
        <Typography variant="body1">
          This portal allows you to manage employee information efficiently.
          Navigate using the links in the navbar to create new employees or view existing employee details.
        </Typography>
      </Paper>
    </Container>
  );
};

export default LandingPage;
