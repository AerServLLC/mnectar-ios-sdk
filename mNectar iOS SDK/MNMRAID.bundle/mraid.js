
//(function (external) {
    var mraid = window.mraid = {};

    mraid._call = function (command) {
        window.location = "mraid://" + command;
    };

    var _version = "2.0";

    mraid.getVersion = function () {
        return _version;
    };

    var _listeners = {};

    mraid._fireEvent = function (event) {
        if (_listeners[event]) {
            var args = Array.prototype.slice.call(arguments);
            args.shift();

            for (var i = 0; i < _listeners[event].length; i++) {
                _listeners[event][i].apply(null, args);
            }
        }
    };

    mraid.addEventListener = function (event, listener) {
        if (!_listeners[event]) {
            _listeners[event] = [];
        }

        _listeners[event].push(listener);
    };

    mraid.removeEventListener = function (event, listener) {
        if (_listeners[event]) {
            if (!listener) {
                _listeners[event].splice(0, _listeners[event].length);
            } else {
                for (var i = _listeners[event].length - 1; i >= 0; i--) {
                    if (_listeners[event][i] === listener) {
                        _listeners[event].splice(i, 1);

                        break;
                    }
                }
            }
        }
    };

    var _state = "loading";

    mraid._setState = function (state) {
        _state = state;
    };

    mraid.getState = function () {
        return _state;
    };

    var _placementType = undefined;

    mraid._setPlacementType = function (placementType) {
        _placementType = placementType;
    };

    mraid.getPlacementType = function () {
        return _placementType;
    };

    var _isViewable = undefined;

    mraid._setIsViewable = function (isViewable) {
        _isViewable = isViewable;
    };

    mraid.isViewable = function () {
        return _isViewable;
    };

    mraid.open = function (url) {
        mraid._call("open?url=" + encodeURIComponent(url));
    };

    mraid.expand = function (url) {
        mraid._call("expand?url=" + encodeURIComponent(url));
    };

    var _expandProperties = {
        "width": undefined,
        "height": undefined,
        "useCustomClose": undefined,
        "isModal": true,
    };

    mraid._getExpandPropertyWidth = function () {
        return _expandProperties["width"];
    };

    mraid._getExpandPropertyHeight = function () {
        return _expandProperties["height"];
    };

    mraid._getExpandPropertyUseCustomClose = function () {
        return _expandProperties["useCustomClose"];
    };

    mraid._setExpandPropertyWidth = function (width) {
        _expandProperties["width"] = width;
    };

    mraid._setExpandPropertyHeight = function (height) {
        _expandProperties["height"] = height;
    };

    mraid._setExpandPropertyUseCustomClose = function (useCustomClose) {
        _expandProperties["useCustomClose"] = useCustomClose;
    };

    mraid.setExpandProperties = function (properties) {
        if (properties.hasOwnProperty("width")) {
            _expandProperties["width"] = properties["width"];
        }

        if (properties.hasOwnProperty("height")) {
            _expandProperties["height"] = properties["height"];
        }

        if (properties.hasOwnProperty("useCustomClose")) {
            _expandProperties["useCustomClose"] = properties["useCustomClose"];

            mraid._call("usecustomclose");
        }
    };

    mraid.getExpandProperties = function () {
        return _expandProperties;
    };

    var _orientationProperties = {
        "allowOrientationChange": undefined,
        "forceOrientation": undefined
    };

    mraid._getOrientationPropertyAllowOrientationChange = function () {
        return _orientationProperties["allowOrientationChange"];
    };

    mraid._getOrientationPropertyForceOrientation = function () {
        return _orientationProperties["forceOrientation"];
    };

    mraid._setOrientationPropertyAllowOrientationChange = function (allowOrientationChange) {
        _orientationProperties["allowOrientationChange"] = allowOrientationChange;
    };

    mraid._setOrientationPropertyForceOrientation = function (orientation) {
        _orientationProperties["forceOrientation"] = orientation;
    };
    
    mraid.setOrientationProperties = function (properties) {
        if (properties.hasOwnProperty("allowOrientationChange")) {
            _orientationProperties["allowOrientationChange"] = properties["allowOrientationChange"];
        }

        if (properties.hasOwnProperty("forceOrientation")) {
            _orientationProperties["forceOrientation"] = properties["forceOrientation"];
        }

        mraid._call("orientation");
    };

    mraid.getOrientationProperties = function () {
        return _orientationProperties;
    };

    mraid.useCustomClose = function (useCustomClose) {
        _expandProperties["useCustomClose"] = useCustomClose;

        mraid._call("usecustomclose");
    };

    mraid.resize = function () {
        mraid._call("resize");
    };

    var _resizeProperties = {
        "width": undefined,
        "height": undefined,
        "offsetX": undefined,
        "offsetY": undefined,
        "customClosePosition": undefined,
        "allowOffscreen": undefined,
    };

    mraid._getResizePropertyWidth = function () {
        return _resizeProperties["width"];
    };

    mraid._getResizePropertyHeight = function () {
        return _resizeProperties["height"];
    };

    mraid._getResizePropertyOffsetX = function () {
        return _resizeProperties["offsetX"];
    };

    mraid._getResizePropertyOffsetY = function () {
        return _resizeProperties["offsetY"];
    };

    mraid._getResizePropertyCustomClosePosition = function () {
        return _resizeProperties["customClosePosition"];
    };

    mraid._getResizePropertyAllowOffscreen = function () {
        return _resizeProperties["allowOffscreen"];
    };

    mraid._setResizePropertyWidth = function (width) {
        _resizeProperties["width"] = width;
    };

    mraid._setResizePropertyHeight = function (height) {
        _resizeProperties["height"] = height;
    };

    mraid._setResizePropertyOffsetX = function (offsetX) {
        _resizeProperties["offsetX"] = offsetX;
    };

    mraid._setResizePropertyOffsetY = function (offsetY) {
        _resizeProperties["offsetY"] = offsetY;
    };

    mraid._setResizePropertyCustomClosePosition = function (customClosePosition) {
        _resizeProperties["customClosePosition"] = customClosePosition;
    };

    mraid._setResizePropertyAllowOffscreen = function (allowOffscreen) {
        _resizeProperties["allowOffscreen"] = allowOffscreen;
    };

    mraid._setResizeProperties = function (properties) {
        if (properties.hasOwnProperty("width")) {
            _resizeProperties["width"] = properties["width"];
        }

        if (properties.hasOwnProperty("height")) {
            _resizeProperties["height"] = properties["height"];
        }

        if (properties.hasOwnProperty("offsetX")) {
            _resizeProperties["offsetX"] = properties["offsetX"];
        }

        if (properties.hasOwnProperty("offsetY")) {
            _resizeProperties["offsetY"] = properties["offsetY"];
        }

        if (properties.hasOwnProperty("customClosePosition")) {
            _resizeProperties["customClosePosition"] = properties["customClosePosition"];
        }

        if (properties.hasOwnProperty("allowOffscreen")) {
            _resizeProperties["allowOffscreen"] = properties["allowOffscreen"];
        }
    };

    mraid.setResizeProperties = function (properties) {
        mraid._setResizeProperties(properties);
    };

    mraid.getResizeProperties = function () {
        return _resizeProperties;
    };

    mraid.close = function () {
        mraid._call("close");
    };

    var _currentPosition = [undefined, undefined, undefined, undefined];

    mraid._setCurrentPosition = function (x, y, w, h) {
        _currentPosition[0] = x;
        _currentPosition[1] = y;
        _currentPosition[2] = w;
        _currentPosition[3] = h;
    };

    mraid.getCurrentPosition = function () {
        return _currentPosition;
    };

    var _maxSize = [undefined, undefined];

    mraid._setMaxSize = function (w, h) {
        _maxSize[0] = w;
        _maxSize[1] = h;
    }

    mraid.getMaxSize = function () {
        return _maxSize;
    };

    var _defaultPosition = [undefined, undefined, undefined, undefined];

    mraid._setDefaultPosition = function (x, y, w, h) {
        _defaultPosition[0] = x;
        _defaultPosition[1] = y;
        _defaultPosition[2] = w;
        _defaultPosition[3] = h;
    };

    mraid.getDefaultPosition = function () {
        return _defaultPosition;
    };

    var _screenSize = [undefined, undefined];
    
    mraid._setScreenSize = function (w, h) {
        _screenSize[0] = w;
        _screenSize[1] = h;
    };
    
    mraid.getScreenSize = function () {
        return _screenSize;
    };

    var _features = [];

    mraid._clearFeatures = function (supports) {
        while (_features.length) {
            _features.pop();
        }
    };

    mraid._addFeature = function (feature) {
        if (_features.indexOf(feature) === -1) {
            _features.push(feature);
        }
    };

    mraid._removeFeature = function (feature) {
        if (_features.indexOf(feature) >= 0) {
            _features.splice(_features.indexOf(feature), 1);
        }
    };

    mraid.supports = function () {
        return _features;
    };
    
    mraid.storePicture = function () {};

    mraid.createCalendarEvent = function () {};

    mraid.playVideo = function () {};
//})(window);

//console.log = function () {
//    mraid._call("log?m=" + encodeURIComponent(Array.prototype.slice.call(arguments).join(' ')));
//};
