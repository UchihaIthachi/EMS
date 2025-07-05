import React, { useState } from 'react';
import { Typography, Container, Paper, Box, TextField, Button, Divider, CircularProgress, Grid } from '@mui/material';
import { useToast } from '../hooks/useToast';
import { getDepartmentByCode } from '../api';

interface DepartmentDetails {
  id: number; // Assuming the backend returns an id
  departmentName: string;
  departmentDescription: string;
  departmentCode: string;
}

const FindDepartmentPage: React.FC = () => {
  const [departmentCode, setDepartmentCode] = useState<string>('');
  const [departmentDetails, setDepartmentDetails] = useState<DepartmentDetails | null>(null);
  const [loading, setLoading] = useState<boolean>(false);
  const [searched, setSearched] = useState<boolean>(false); // To know if a search has been attempted
  const toast = useToast();

  const handleCodeChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setDepartmentCode(event.target.value);
    if (searched) { // Reset details if code changes after a search
      setDepartmentDetails(null);
      setSearched(false);
    }
  };

  const handleSearch = async (event: React.FormEvent<HTMLFormElement> | React.MouseEvent<HTMLButtonElement>) => {
    event.preventDefault();
    if (!departmentCode.trim()) {
      toast.showToast('Please enter a Department Code to search.', 'warning');
      return;
    }
    setLoading(true);
    setSearched(true);
    setDepartmentDetails(null); // Clear previous results before new search
    try {
      const response = await getDepartmentByCode(departmentCode.trim());
      if (response.data) {
        setDepartmentDetails(response.data);
      } else {
        toast.showToast('Department not found.', 'info');
      }
    } catch (error: any) {
      console.error('Failed to find department:', error);
      if (error.response && error.response.status === 404) {
        toast.showToast(`Department with code '${departmentCode.trim()}' not found.`, 'error');
      } else {
        const errorMessage = error.response?.data?.message || error.response?.data || 'Failed to fetch department details.';
        toast.showToast(errorMessage, 'error');
      }
      setDepartmentDetails(null);
    } finally {
      setLoading(false);
    }
  };

  return (
    // Removed mt: 4. MainLayout's padding and AppBar spacing should be sufficient.
    <Container maxWidth="md" sx={{ mb: 4 }}>
      <Paper elevation={3} sx={{ p: 4 }}>
        <Typography variant="h6" color="primary" gutterBottom>
          🔍 Find Department by Code
        </Typography>
        <Divider sx={{ mb: 3 }} />
        <Box component="form" onSubmit={handleSearch} noValidate autoComplete="off" sx={{ display: 'flex', alignItems: 'flex-start', mb: 3 }}>
          <TextField
            label="Department Code"
            variant="outlined"
            value={departmentCode}
            onChange={handleCodeChange}
            sx={{ mr: 2, flexGrow: 1 }}
            disabled={loading}
            onKeyPress={(e) => { // Allow submission with Enter key
              if (e.key === 'Enter') {
                handleSearch(e as any); // Type assertion, as FormEvent is expected by handleSearch
              }
            }}
          />
          <Box sx={{ position: 'relative' }}>
            <Button
              type="submit"
              variant="contained"
              color="primary"
              disabled={loading || !departmentCode.trim()}
              onClick={handleSearch} // Ensure button click also triggers search
            >
              Search
            </Button>
            {loading && (
              <CircularProgress
                size={24}
                sx={{
                  color: 'primary.main',
                  position: 'absolute',
                  top: '50%',
                  left: '50%',
                  marginTop: '-12px',
                  marginLeft: '-12px',
                }}
              />
            )}
          </Box>
        </Box>

        {searched && !loading && departmentDetails && (
          <Box mt={3}>
            <Typography variant="h6" gutterBottom sx={{ color: 'primary.dark' }}>Department Details:</Typography>
            <Paper variant="outlined" sx={{ p: 2, backgroundColor: '#f9f9f9' }}>
              <Grid container spacing={1}>
                <Grid item xs={12} sm={4}>
                  <Typography variant="subtitle2" fontWeight="bold">Name:</Typography>
                </Grid>
                <Grid item xs={12} sm={8}>
                  <Typography>{departmentDetails.departmentName}</Typography>
                </Grid>
                <Grid item xs={12} sm={4}>
                  <Typography variant="subtitle2" fontWeight="bold">Description:</Typography>
                </Grid>
                <Grid item xs={12} sm={8}>
                  <Typography>{departmentDetails.departmentDescription}</Typography>
                </Grid>
                <Grid item xs={12} sm={4}>
                  <Typography variant="subtitle2" fontWeight="bold">Code:</Typography>
                </Grid>
                <Grid item xs={12} sm={8}>
                  <Typography>{departmentDetails.departmentCode}</Typography>
                </Grid>
                 {/* Assuming 'id' might be part of the response, display if available */}
                {departmentDetails.id && (
                  <>
                    <Grid item xs={12} sm={4}>
                      <Typography variant="subtitle2" fontWeight="bold">ID:</Typography>
                    </Grid>
                    <Grid item xs={12} sm={8}>
                      <Typography>{departmentDetails.id}</Typography>
                    </Grid>
                  </>
                )}
              </Grid>
            </Paper>
          </Box>
        )}
        {searched && !loading && !departmentDetails && (
          <Box mt={3}>
            <Typography sx={{ color: 'text.secondary' }}>
              No department found for the entered code.
            </Typography>
          </Box>
        )}
      </Paper>
    </Container>
  );
};

export default FindDepartmentPage;
