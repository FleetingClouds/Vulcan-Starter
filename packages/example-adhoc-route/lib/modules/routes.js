import { addRoute } from 'meteor/vulcan:core';

addRoute({ name: 'movies', path: '/', componentName: 'MoviesList' });
addRoute({ name: 'movies.single', path: 'movie/:slug', componentName: 'MoviesGet' });
addRoute({ name: 'movies.adhoc', path: 'movie', componentName: 'MoviesAdhoc' });

addRoute({ name: 'moofies.adhoc', path: 'moofie', componentName: 'MoofiesAdhoc' });
