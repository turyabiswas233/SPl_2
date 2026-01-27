/**
 * Response Formatter Utility
 * Standardizes API responses
 */

const successResponse = (res, statusCode = 200, data = null, message = null) => {
  const response = {
    success: true,
    ...(message && { message }),
    ...(data && { data })
  };
  return res.status(statusCode).json(response);
};

const errorResponse = (res, statusCode = 500, message = "Internal Server Error") => {
  return res.status(statusCode).json({
    success: false,
    error: message
  });
};

module.exports = {
  successResponse,
  errorResponse
};
