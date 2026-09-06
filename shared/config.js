// shared/config.js
//
// Single source of truth for the backend API URL. Previously this was
// hardcoded as 'http://localhost:3000/api' inside 7+ separate HTML files,
// which meant deploying anywhere but localhost required editing every page.
// Now it's defined once here, and every page loads this file with:
//   <script src="../shared/config.js"></script>
//
// To point the frontend at a different backend (e.g. after deploying),
// change ONLY the line below.
const API_BASE_URL = 'http://localhost:3000/api';

/**
 * Fetch wrapper that automatically attaches the JWT stored in localStorage
 * (if present) as a Bearer token, and prefixes the path with API_BASE_URL.
 *
 * Use this for any request to an endpoint protected by the backend's
 * authenticateToken middleware (profile, booking creation, etc.).
 *
 * @param {string} path - endpoint path starting with '/', e.g. '/profile/5'
 * @param {RequestInit} [options] - standard fetch options
 */
async function authFetch(path, options = {}) {
    const token = localStorage.getItem('token');
    const headers = {
        'Content-Type': 'application/json',
        ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
        ...(options.headers || {})
    };

    return fetch(`${API_BASE_URL}${path}`, { ...options, headers });
}
