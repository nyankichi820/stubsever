'use strict';
var  path = require('path');
 
module.exports = function(grunt) {
    var pkg, taskName;
    pkg = grunt.file.readJSON('package.json');
    grunt.initConfig({
        bower: {
          install: {
            options: {
              targetDir: 'public/js/lib', 
              layout: 'byType', 
              install: true, 
              verbose: true, 
              cleanTargetDir: true, 
              cleanBowerDir: false 
            }
          }
        },
        sass: {
            options: {
                style: 'compressed',
                sourcemap: true,
                noCache: true
            },
            styles: {
                src:  'sass/style.scss',
                dest: 'public/css/style.css'
            }
        },
    });
 
    for(taskName in pkg.devDependencies) {
        if(taskName.substring(0, 6) == 'grunt-') {
            grunt.loadNpmTasks(taskName);
        }
    }
 
    grunt.registerTask('default', ['bower', 'dist_css']);
    grunt.registerTask('dist_css', ['sass']);
 
    grunt.registerTask('eatwarnings', function() {
        grunt.warn = grunt.fail.warn = function(warning) {
            grunt.log.error(warning);
        };
    });
};
