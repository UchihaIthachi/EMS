import React, { useState } from 'react';
import { getEmployee } from '../api';

export default function EmployeeDetails() {
  const [id, setId] = useState('');
  const [data, setData] = useState<any>(null);

  const fetchDetails = async () => {
    try {
      const res = await getEmployee(id);
      setData(res.data);
    } catch {
      alert('Employee not found');
    }
  };

  return (
    <div>
      <input
        placeholder="Employee ID"
        value={id}
        onChange={e => setId(e.target.value)}
      />
      <button onClick={fetchDetails}>Fetch Employee</button>
      {data && (
        <pre>{JSON.stringify(data, null, 2)}</pre>
      )}
    </div>
  );
}
