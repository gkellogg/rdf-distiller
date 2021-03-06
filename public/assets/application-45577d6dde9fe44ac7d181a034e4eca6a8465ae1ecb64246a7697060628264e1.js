/*global $, angular*/
/*jshint unused:false*/


var distilApp = angular.module('distillerApp', ['ngRoute', 'ngSanitize'])
  .config(['$routeProvider', '$locationProvider', '$logProvider', '$httpProvider',
    function($routeProvider, $locationProvider, $logProvider, $httpProvider) {
      /*jshint unused:true*/

      $locationProvider.html5Mode({enabled: true, rewriteLinks: false});
      $logProvider.debugEnabled(true);
      $routeProvider.
        when('/distiller', {
          controller: 'DistillerController'
        });
        $httpProvider.defaults.headers.common.Accept = "application/json, text/plain&q=0.1";
        $httpProvider.defaults.headers.common['X-Requested-With'] = 'XMLHttpRequest';
    }
  ])
  .controller('DistillerController', ['$scope', '$http', '$location',
              'CommandData', 'OptionData', 'InputFormatOptionData', 'OutputFormatOptionData',
    function ($scope, $http, $location,
              commandData, optionData, inputFormatOptionData, outputFormatOptionData) {
      $scope.loading = null;      // show page loading symbol
      $scope.useAlt = false;      // Use alternate input
      $scope.alternate = null;    // Alternate URL to directly access distiller

      // Initialized from HTML
      $scope.orderedOpts = optionData;

      // Clear out nonuseful options
      var removeEmpty = function(obj) { 
        return Object.keys(obj)
          .filter(function(f) {return obj[f] && obj[f] !== "";})
          .reduce(function(r, i) { 
            r[i] = obj[i];
            return r;
          }, {});
      };

      // Clear out input-like options
      var removeInput = function(obj) { 
        return Object.keys(obj)
          .filter(function(f) {return !f.match(/input$/i);})
          .reduce(function(r, i) { 
            r[i] = obj[i];
            return r;
          }, {});
      };

      // Called when a select field or command menu item is updated, which can change displayed commands and options
      $scope.update = function(command) {
        // Update command with associated options and determine appropriate commands and options to display
        $scope.options.command = command;

        // Set options to the default, plus those for the command, minus those that have no datatype.
        var cmd = commandData.find(function(c) {return c.symbol === command;});
        var cmdOptions = cmd.options || [];

        $scope.description = cmd.description;

        // Set of commnads used for options

        // Update commands based on input/output formats
        // Set available command based on selected format and output_format
        $scope.commands = commandData
          .filter(function(c) {
            var useCmd = c.control !== 'button'; // buttons come elsewhere
            $.each((c.filter || {}), function(opt, value) {
              if ($scope.options[opt] !== value) {
                useCmd = false;
              }
            });
            // Use the command, unless it's excluded
            return useCmd;
          })
        .map(function(c) {return c.symbol;})
        .sort();

        // Command modifiers, also based on formats
        $scope.modifiers = commandData
          // buttons come elsewhere
          .filter(function(c) {return c.control === 'button';})
          // Indicate use/disuse rather than filter out if not appropriate
          .map(function(c) {
            var use = true;
            $.each((c.filter || {}), function(opt, value) {
              if ($scope.options[opt] !== value) {use = false;}
            });
            // Add command options from modifiers for enabled commands
            if ($scope.options[c.symbol]) {
              cmdOptions = cmdOptions.concat(c.options || []);
            }

            return $.extend({}, c, {use: use});
          })
          .sort(function(obj) {return obj.symbol;});

        // Update options based on input/output formats
        // Iterate over options in order of precidence to exclude repetition
        // jshint camelcase: false
        var optMap = cmdOptions.concat(
          (inputFormatOptionData[$scope.options.format] || []),
          (outputFormatOptionData[$scope.options.output_format] || []),
          optionData)
        .map(function(opt) {
          // Update usage from command
          if ((cmd.option_use || {})[opt.symbol]) {
            opt = $.extend({}, opt, {use: cmd.option_use[opt.symbol]});
          }
          return opt;
        })
        .reduce(function(result, opt) {
          // Only add the option if not already in the map (result)
          result[opt.symbol] = result[opt.symbol] || opt;
          return result;
        }, {});
        // jshint camelcase: true

        // Set options from optMap, excluding those with no control
        $scope.orderedOpts = Object.values(optMap)
          .filter(function(opt) {return opt.control;}) // opts with no control
          .sort(function(a, b) {
            return (a.symbol > b.symbol) ? 1 : ((b.symbol > a.symbol) ? -1 : 0); 
          });

        // Show second input if any option using control url2
        $scope.useAlt = $scope.orderedOpts.some(function(opt) {
          return opt.control === 'url2';
        });
      };

      // Use options to run distiller command and display results
      $scope.distil = function() {
        $scope.loading = true;
        $scope.result = null;
        $http({
          method: "POST",
          url: "/distiller",
          data: removeEmpty($scope.options),
          cache: false
        }).then(function(response) {
          $scope.result = response.data;
          $scope.loading = false;
        }, function(response) {
          $scope.result = response.data;
          $scope.loading = false;
        });
      };

      // Update textarea by loading associated URL
      $scope.load = function(url, opt) {
        $http.get("/distiller/load", {params: {url: url}, cache: false})
          .then(function(response) {
            $scope.options[opt] = response.data;
          })
          .catch(function(response) {
            // Indicate load error
          });
      };

      $scope.$watch("options | json", function() {
        // Update URI parameters and alternate access
        $location.url($location.path()); // Clear parameters
        $location.search(removeInput(removeEmpty($scope.options)));  // Add scope
        $scope.alternate = $location.absUrl();
      });

      $scope.options = $location.search();
      $scope.update($scope.options.command || 'serialize');

      // If there are routeParams, use them to initialize the controller
      if ($location.search().url) {
        $scope.distil();
      }
    }
  ]);
