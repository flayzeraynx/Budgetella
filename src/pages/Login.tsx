import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import Login from '../components/auth/Login';
import Layout from '../components/layout/Layout';

const LoginPage: React.FC = () => {
  const { currentUser, isLoading } = useAuth();

  // If user is already logged in, redirect to dashboard
  if (currentUser && !isLoading) {
    return <Navigate to="/" replace />;
  }

  return (
    <Layout>
      <div className="max-w-md mx-auto mt-10">
        <Login />
      </div>
    </Layout>
  );
};

export default LoginPage;
