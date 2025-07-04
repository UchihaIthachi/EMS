import React from 'react';
import { AppBar, Toolbar, Typography, Button } from '@mui/material';
import { Link } from 'react-router-dom';

const Navbar: React.FC = () => {
  return (
    <AppBar position="static">
      <Toolbar>
        <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
          Employee Portal
        </Typography>
        <Button color="inherit" component={Link} to="/">Home</Button>
        <Button color="inherit" component={Link} to="/create-employee">Create Employee</Button>
        <Button color="inherit" component={Link} to="/employee-details">Employee Details</Button>
        <Button color="inherit" component={Link} to="/create-department">Create Department</Button>
        <Button color="inherit" component={Link} to="/department-details">Department Details</Button>
        <Button color="inherit" component={Link} to="/messages">Service Messages</Button>
      </Toolbar>
    </AppBar>
  );
};

export default Navbar;
