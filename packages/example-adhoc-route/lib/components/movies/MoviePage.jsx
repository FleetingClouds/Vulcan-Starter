import { Components, registerComponent, withDocument, withCurrentUser } from 'meteor/vulcan:core';
import React from 'react';
import { FormattedMessage } from 'meteor/vulcan:i18n';
import Movies from '../../modules/movies/collection.js';
import { Link } from 'react-router';

const MoviePage = (props) => {

  if (props.loading) {

    return <div className="page movies-profile"><Components.Loading/></div>

  } else if (!props.document) {

    console.log(`// missing movie (_id/slug: ${props.documentId || props.slug})`);
    return <div className="page movies-profile"><FormattedMessage id="app.404"/></div>

  } else {

    const movie = props.document;

    const terms = {view: "moviePosts", movieId: movie._id};

    return (
      <div className="page users-profile">
        {movie.name
          ? (
              <div>
                <div><b>Name</b> : {movie.name} ({movie.year})</div>
                <div><b>Review</b> : {movie.review}</div>
              </div>
            )
          : ( <div>Misfire.  Try again.</div> )
        }
      </div>
    )
  }
}

MoviePage.propTypes = {
  // document: PropTypes.object.isRequired,
}

MoviePage.displayName = "MoviePage";

const options = {
  collection: Movies,
  queryName: 'moviesSingleQuery',
  fragmentName: 'MoviePageFragment',
};

registerComponent('MoviePage', MoviePage, withCurrentUser, [withDocument, options]);
