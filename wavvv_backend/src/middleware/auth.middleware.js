const { verifyFirebaseToken } = require('../config/firebase');
const User = require('../models/User');

const authMiddleware = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Unauthorized: No token provided' });
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
      return res.status(401).json({ error: 'Unauthorized: Token is empty' });
    }

    let decodedToken;
    try {
      decodedToken = await verifyFirebaseToken(token);
    } catch (err) {
      return res.status(401).json({ error: `Unauthorized: Token verification failed: ${err.message}` });
    }

    // Retrieve corresponding user from MongoDB
    const user = await User.findOne({ firebaseUid: decodedToken.uid });

    req.firebaseUser = decodedToken;
    req.user = user; // Note: req.user may be null if username screen has not been completed.

    next();
  } catch (error) {
    console.error('Auth middleware error:', error);
    res.status(500).json({ error: 'Internal server error in auth verification' });
  }
};

module.exports = authMiddleware;
