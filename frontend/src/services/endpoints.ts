export const endpoints = {
  auth: {
    login: '/auth/login',
    verify: '/auth/verify',
    health: '/auth/health'
  },
  users: {
    me: '/api/v1/users/me',
    byId: (id: number) => `/api/v1/users/${id}`
  },
  doctors: {
    list: '/api/doctors/'
  },
  appointments: {
    list: '/api/appointments/'
  },
  notifications: {
    list: '/api/notifications/'
  }
};

export default endpoints;
