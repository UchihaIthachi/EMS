import React from 'react';
import { Typography, Container, Paper, Box } from '@mui/material';

const LandingPage: React.FC = () => {
  return (
    <Container maxWidth="md" sx={{ mt: 5, mb: 5 }}>
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
