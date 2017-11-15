/*

An item in the movies list.
Wrapped with the "withCurrentUser" container.

*/

import React from 'react';
import { Components, registerComponent } from 'meteor/vulcan:core';
import { withRouter } from 'react-router';

import Movies from '../../modules/movies/collection.js';

const MoviesItem = ({  loading, router  }) => {

    var movie = Movies.find({ name: router.location.query.name }).fetch()[0];
    console.log( 'Loaded movie :: ', movie );
    return (
      <div>
        <div> <b>name :</b> { router.location.query.name }</div>

        { 0 === 1
            ? <div> <b>year :</b> { movie.year } <b>review :</b> { movie.review }</div>
            : movie
              ? <div> <b>year :</b> { movie.year } <b>review :</b> { movie.review }</div>
              : 'NUTHIN'
        }
      </div>
    );
}

registerComponent('MoviesItem', withRouter(MoviesItem));

        // { movie ?
        //   <div>
        //     <div> year : { movie.year }</div>
        //     <div> review : { movie.review }</div>
        //   </div> :
        //   'null'
        // }
