/**
 * Custom log function
 * @param {string} message - The message to log
 * @param {'info' | 'error' | 'warn'} type - The type of log message
 */
const clog = (message, type) => {
  const timestamp = new Date().toLocaleString();
  // set style color for log message. 
  const color = type === "error" ? "\x1b[31m" : type === "warn" ? "\x1b[33m" : "\x1b[32m";
  console.log(`${color}[${timestamp}] ${message}\x1b[0m`);
  console.log("\x1b[0m"); // Reset color
}


module.exports = {
  clog,
};