const joi = require('joi');

const validate = (schema) => (req, res, next) => {
  const validKeys = ['params', 'query', 'body'];
  const object = {};

  validKeys.forEach((key) => {
    if (req[key] && schema[key]) {
      object[key] = req[key];
    }
  });

  const schemaToValidate = joi.object(
    Object.keys(object).reduce((acc, key) => {
      acc[key] = schema[key];
      return acc;
    }, {})
  );

  const { value, error } = schemaToValidate.validate(object, {
    abortEarly: false,
    allowUnknown: true,
    stripUnknown: true,
  });

  if (error) {
    const errorMessage = error.details.map((details) => details.message).join(', ');
    return res.status(400).json({ error: errorMessage });
  }

  // Assign validated and stripped variables back to request
  Object.assign(req, value);
  return next();
};

module.exports = validate;
