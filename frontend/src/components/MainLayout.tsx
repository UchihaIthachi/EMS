import React, { useState } from 'react';
import { Box, CssBaseline, AppBar, Toolbar, IconButton, Typography, Drawer, List, ListItem, ListItemIcon, ListItemText, Divider, useTheme } from '@mui/material'; // Removed createTheme, ThemeProvider, using useTheme
import MenuIcon from '@mui/icons-material/Menu';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import { Link as RouterLink } from 'react-router-dom';
import HomeIcon from '@mui/icons-material/Home';
import AddCircleOutlineIcon from '@mui/icons-material/AddCircleOutline';
import FindInPageIcon from '@mui/icons-material/FindInPage';
import BusinessIcon from '@mui/icons-material/Business'; // For department
import GroupAddIcon from '@mui/icons-material/GroupAdd'; // For create employee
import InfoIcon from '@mui/icons-material/Info';


// Define your navigation items here
const navItems = [
  { text: 'Home', path: '/', icon: <HomeIcon /> },
  { text: 'Create Employee', path: '/create-employee', icon: <GroupAddIcon /> },
  { text: 'Employee Details', path: '/employee-details', icon: <FindInPageIcon /> },
  { text: 'Create Department', path: '/create-department', icon: <AddCircleOutlineIcon /> }, // Using AddCircle for generic create
  { text: 'Department Details', path: '/department-details', icon: <BusinessIcon /> },
  { text: 'Service Messages', path: '/messages', icon: <InfoIcon /> },
];

const drawerWidth = 280; // Slightly wider for right sidebar with icons

interface MainLayoutProps {
  children: React.ReactNode;
}

const MainLayout: React.FC<MainLayoutProps> = ({ children }) => {
  const theme = useTheme(); // Use theme from context
  const [open, setOpen] = useState(false);

  const handleDrawerOpen = () => {
    setOpen(true);
  };

  const handleDrawerClose = () => {
    setOpen(false);
  };

  return (
    <Box sx={{ display: 'flex' }}>
      <CssBaseline /> {/* Ensures consistent baseline styles */}
      <AppBar
        position="fixed"
        sx={{
          zIndex: theme.zIndex.drawer + 1,
          transition: theme.transitions.create(['width', 'margin'], {
            easing: theme.transitions.easing.sharp,
            duration: theme.transitions.duration.leavingScreen,
          }),
          ...(open && {
            marginRight: drawerWidth, // Adjusted for right drawer
            width: `calc(100% - ${drawerWidth}px)`,
            transition: theme.transitions.create(['width', 'margin'], {
              easing: theme.transitions.easing.sharp,
              duration: theme.transitions.duration.enteringScreen,
            }),
          }),
        }}
      >
        <Toolbar>
          <Typography variant="h6" noWrap component="div" sx={{ flexGrow: 1 }}>
            Employee Portal
          </Typography>
          <IconButton
            color="inherit"
            aria-label="open drawer"
            onClick={handleDrawerOpen}
            edge="end" // Align to the end for right drawer
            sx={{ ...(open && { display: 'none' }) }}
          >
            <MenuIcon />
          </IconButton>
        </Toolbar>
      </AppBar>
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          p: 3,
          transition: theme.transitions.create('margin', {
            easing: theme.transitions.easing.sharp,
            duration: theme.transitions.duration.leavingScreen,
          }),
          marginRight: 0, // Initial state when drawer is closed
          marginTop: '64px', // Account for AppBar height (default MUI AppBar height)
          ...(open && {
            transition: theme.transitions.create('margin', {
              easing: theme.transitions.easing.easeOut,
              duration: theme.transitions.duration.enteringScreen,
            }),
            marginRight: `${drawerWidth}px`, // Push content to left when right drawer opens
          }),
        }}
      >
        {children}
      </Box>
      <Drawer
        variant="persistent"
        anchor="right" // Changed to right
        open={open}
        sx={{
          width: drawerWidth,
          flexShrink: 0,
          '& .MuiDrawer-paper': {
            width: drawerWidth,
            boxSizing: 'border-box',
          },
        }}
      >
        <Toolbar
          sx={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'flex-start', // Align icon to the start for right drawer
            px: [1],
            // necessary for content to be below app bar
            ...theme.mixins.toolbar, // Use theme from context
          }}
        >
          <IconButton onClick={handleDrawerClose}>
            <ChevronRightIcon /> {/* Changed icon to point right for closing a right drawer */}
          </IconButton>
        </Toolbar>
        <Divider />
        <List>
          {navItems.map((item) => (
            <ListItem button component={RouterLink} to={item.path} key={item.text} onClick={() => { item.path !== '#' && handleDrawerClose(); }}>
              <ListItemIcon>{item.icon}</ListItemIcon>
              <ListItemText primary={item.text} />
            </ListItem>
          ))}
        </List>
      </Drawer>
    </Box>
  );
};

export default MainLayout;
