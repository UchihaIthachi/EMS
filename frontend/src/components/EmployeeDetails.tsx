import React, { useState } from 'react';
import {
  TextField,
  Button,
  Box,
  Typography,
  Snackbar,
  Alert,
  Grid,
  Paper
} from '@mui/material';
import SearchIcon from '@mui/icons-material/Search';
import { getEmployee } from '../api';
import { useToast } from '../hooks/useToast';

export default function EmployeeDetails() {
  const [id, setId] = useState('');
  const [data, setData] = useState<any>(null);
  const toast = useToast();

  const fetchDetails = async () => {
    if (!id.trim()) {
      toast.showToast('Please enter an Employee ID', 'warning');
      return;
    }

    try {
      const res = await getEmployee(id);
      setData(res.data);
      toast.showToast('Employee data loaded successfully!', 'success');
    } catch {
      setData(null);
      toast.showToast('Employee not found', 'error');
    }
  };

  return (
    <Box mt={2}>
      <Typography variant="subtitle1" gutterBottom>
        Enter Employee ID to fetch details
      </Typography>

      <Grid container spacing={2} alignItems="center">
        <Grid item xs={12} sm={8}>
          <TextField
            fullWidth
            label="Employee ID"
            variant="outlined"
            value={id}
            onChange={(e) => setId(e.target.value)}
            helperText="Enter a valid numeric ID"
          />
        </Grid>
        <Grid item xs={12} sm={4}>
          <Button
            fullWidth
            onClick={fetchDetails}
            variant="contained"
            color="primary"
            size="large"
            startIcon={<SearchIcon />}
          >
            Fetch
          </Button>
        </Grid>
      </Grid>

      <Box mt={4}>
        {data ? (
          <Paper elevation={2} sx={{ p: 3, backgroundColor: '#f9f9f9' }}>
            <Typography variant="subtitle2" color="textSecondary" gutterBottom>
              Employee JSON Output:
            </Typography>
            <Typography
              variant="body2"
              component="pre"
              sx={{
                fontFamily: 'monospace',
                whiteSpace: 'pre-wrap',
                wordBreak: 'break-word',
              }}
            >
              {JSON.stringify(data, null, 2)}
            </Typography>
          </Paper>
        ) : (
          <Typography variant="body2" color="text.disabled" mt={2}>
            No data to display.
          </Typography>
        )}
      </Box>

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
  );
}
