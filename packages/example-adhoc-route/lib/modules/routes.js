import { addRoute } from 'meteor/vulcan:core';

addRoute({ name: 'movies', path: '/', componentName: 'MoviesList' });
addRoute({ name: 'movie', path: '/movie', componentName: 'MoviesItem' });
