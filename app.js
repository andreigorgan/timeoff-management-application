
var express      = require('express');
var path         = require('path');
var favicon      = require('serve-favicon');
var logger       = require('morgan');
var cookieParser = require('cookie-parser');
var bodyParser   = require('body-parser');
var moment       = require('moment');

var app = express();

// View engine setup
var handlebars = require('express-handlebars')
    .create({
        defaultLayout : 'main',
        extname       : '.hbs',
        helpers : {
            // Handlebars does not allow to have conditions in IF, here is
            // workaround picked from here: http://stackoverflow.com/questions/8853396/logical-operator-in-a-handlebars-js-if-conditional
            if_equal :  function(v1, v2, options){
                if(v1 === v2) {
                    return options.fn(this);
                }
                return options.inverse(this);
            },

            as_date : function(date_string) {
              return moment(date_string).format('YYYY-MM-DD');
            },
        }
    });

app.engine('.hbs', handlebars.engine);
app.set('view engine', '.hbs');

// uncomment after placing your favicon in /public
//app.use(favicon(__dirname + '/public/favicon.ico'));
app.use(logger('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));



// Setup authentication mechanism
var passport = require('./lib/passport')();

app.use(require('express-session')({
    secret            : 'my dirty secret ;khjsdkjahsdajhasdam,nnsnad,',
    resave            : false,
    saveUninitialized : false
}));
app.use(passport.initialize());
app.use(passport.session());



// Custom middlewares
//
// Make sure session object is available in templates
app.use(function(req,res,next){
    res.locals.session = req.session;
    next();
});

app.use(function(req,res,next){
    res.locals.custom_java_script = [];
    res.locals.custom_css = [];
    next();
});

// Enable flash messages within session
app.use( require('./lib/middleware/flash_messages') );


// Here will be publicly accessible routes


app.use(
    '/',
    require('./lib/route/login')(passport),

    // All rotes bellow are only for authenticated users
    require('./lib/route/dashboard.js')
);

app.use(
    '/calendar/',
    require('./lib/route/calendar.js')
);

app.use(
    '/settings/',
    require('./lib/route/settings.js')
);

app.use(
    '/users/',
    require('./lib/route/users.js')
);


// catch 404 and forward to error handler
app.use(function(req, res, next) {
    var err = new Error('Not Found');
    err.status = 404;
    next(err);
});


// error handlers

// development error handler
// will print stacktrace
if (app.get('env') === 'development') {
    app.use(function(err, req, res, next) {
        res.status(err.status || 500);
        res.render('error', {
            message: err.message,
            error: err
        });
    });
}

// production error handler
// no stacktraces leaked to user
app.use(function(err, req, res, next) {
    res.status(err.status || 500);
    res.render('error', {
        message: err.message,
        error: {}
    });
});

module.exports = app;
