/*

An item in the movies list.
Wrapped with the "withCurrentUser" container.

*/

import React from 'react';
// import { Components, registerComponent, withDocument } from 'meteor/vulcan:core';
import { Components, registerComponent } from 'meteor/vulcan:core';
import { withRouter } from 'react-router';

import Movies from '../../modules/movies/collection.js';

const MoviesItem = ({  loading, router  }) => {

  if (loading) {

    console.log("Loading.....");
    return <div className="movies-item"><Components.Loading/></div>

  } else {

    var movie = Movies.find({ name: router.location.query.name }).fetch()[0];
    console.log('...............');
    console.log(  movie.review );
    console.log('...............');
    return (
      <div>
        <div>{ router.location.query.name }</div>
        Name.  { movie.name }<br/>
        Year.  { movie.year }<br/>
        Review.  { movie.review }<br/>
      </div>

    );
  }
}


registerComponent('MoviesItem', withRouter(MoviesItem));
// registerComponent('MoviesItem', withRouter(MoviesItem), [withDocument]);
