import { addRoute } from 'meteor/vulcan:core';

addRoute({ name: 'movies', path: '/', componentName: 'MoviesList' });
addRoute({ name: 'movies.single', path: 'movie/:slug', componentName: 'MoviesGet' });
addRoute({ name: 'movies.adhoc', path: 'movie', componentName: 'MoviesAdhoc' });

// addRoute({ name: 'moofies', path: '/moofies', componentName: 'MoofiesList' });
// addRoute({ name: 'moofies.single', path: 'moofie/:slug', componentName: 'MoofiesGet' });
addRoute({ name: 'moofies.adhoc', path: 'moofie', componentName: 'MoofiesAdhoc' });
