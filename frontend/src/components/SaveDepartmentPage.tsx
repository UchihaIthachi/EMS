import React, { useState } from 'react';
import { Typography, Container, Paper, Box, TextField, Button, Divider, CircularProgress } from '@mui/material';
import { useToast } from '../hooks/useToast';
import { saveDepartment } from '../api';

interface DepartmentFormState {
  departmentName: string;
  departmentDescription: string;
  departmentCode: string;
}

const initialFormState: DepartmentFormState = {
  departmentName: '',
  departmentDescription: '',
  departmentCode: '',
};

const SaveDepartmentPage: React.FC = () => {
  const [formState, setFormState] = useState<DepartmentFormState>(initialFormState);
  const [loading, setLoading] = useState<boolean>(false);
  const [errors, setErrors] = useState<Partial<DepartmentFormState>>({});
  const toast = useToast();

  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = event.target;
    setFormState((prevState) => ({
      ...prevState,
      [name]: value,
    }));
    // Clear error for the field being changed
    if (errors[name as keyof DepartmentFormState]) {
      setErrors((prevErrors) => ({
        ...prevErrors,
        [name]: undefined,
      }));
    }
  };

  const validateForm = (): boolean => {
    const newErrors: Partial<DepartmentFormState> = {};
    if (!formState.departmentName.trim()) newErrors.departmentName = 'Department Name is required';
    if (!formState.departmentDescription.trim()) newErrors.departmentDescription = 'Department Description is required';
    if (!formState.departmentCode.trim()) newErrors.departmentCode = 'Department Code is required';
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!validateForm()) {
      toast.showToast('Please fill in all required fields.', 'error');
      return;
    }

    setLoading(true);
    try {
      await saveDepartment(formState);
      toast.showToast('Department saved successfully!', 'success');
      setFormState(initialFormState); // Reset form
      setErrors({});
    } catch (error: any) {
      console.error('Failed to save department:', error);
      const errorMessage = error.response?.data?.message || error.response?.data || 'Failed to save department. Please try again.';
      toast.showToast(errorMessage, 'error');
    } finally {
      setLoading(false);
    }
  };

  return (
    // Removed mt: 4. MainLayout's padding and AppBar spacing should be sufficient.
    <Container maxWidth="md" sx={{ mb: 4 }}>
      <Paper elevation={3} sx={{ p: 4 }}>
        <Typography variant="h6" color="primary" gutterBottom>
          ➕ Create New Department
        </Typography>
        <Divider sx={{ mb: 3 }} />
        <Box component="form" noValidate autoComplete="off" onSubmit={handleSubmit}>
          <TextField
            name="departmentName"
            label="Department Name"
            variant="outlined"
            fullWidth
            value={formState.departmentName}
            onChange={handleChange}
            error={!!errors.departmentName}
            helperText={errors.departmentName}
            sx={{ mb: 2 }}
            disabled={loading}
          />
          <TextField
            name="departmentDescription"
            label="Department Description"
            variant="outlined"
            fullWidth
            multiline
            rows={3}
            value={formState.departmentDescription}
            onChange={handleChange}
            error={!!errors.departmentDescription}
            helperText={errors.departmentDescription}
            sx={{ mb: 2 }}
            disabled={loading}
          />
          <TextField
            name="departmentCode"
            label="Department Code"
            variant="outlined"
            fullWidth
            value={formState.departmentCode}
            onChange={handleChange}
            error={!!errors.departmentCode}
            helperText={errors.departmentCode}
            sx={{ mb: 3 }}
            disabled={loading}
          />
          <Box sx={{ position: 'relative', display: 'inline-block' }}>
            <Button
              type="submit"
              variant="contained"
              color="primary"
              disabled={loading}
            >
              Save Department
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
      </Paper>
    </Container>
  );
};

export default SaveDepartmentPage;
