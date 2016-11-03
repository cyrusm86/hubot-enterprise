if (process.env.USE_FLUENTD) {
  let fluent = require('fluent-logger');

  fluent.configure('hubotEnterprise', {
    host: 'logger',
    port: 24224,
    timeout: 3.0,
    reconnectInterval: 600000 // 10 minutes
  });

  let log = {};
  log.info = function(string) {
    fluent.emit('Info', {message: string});
  };

  log.debug = function(string) {
    fluent.emit('Debug', {message: string});
  };

  log.error = function(string) {
    fluent.emit('Error', {message: string});
  };

  log.warn = function(string) {
    fluent.emit('Warning', {message: string});
  };

  log.warning = function(string) {
    fluent.emit('Warning', {message: string});
  };

  exports.info = log.info;
  exports.debug = log.debug;
  exports.error = log.error;
  exports.warn = log.warn;
  exports.warning = log.warning;
} else {
  module.exports = exports = require('winston');
}
