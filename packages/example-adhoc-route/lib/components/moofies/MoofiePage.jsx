import { Components, registerComponent, withDocument, withCurrentUser } from 'meteor/vulcan:core';
import React from 'react';
import Moofies from '../../modules/moofies/collection.js';
const LG = (msg) => console.log('Within %s...\n  |%s', module.id, msg);

const MoofiePage = (props) => {

  if (props.loading) {

    return <div className="page movies-profile"><Components.Loading/></div>

  } else if (!props.document) {

    console.log(`// missing movie (_id/slug: ${props.documentId || props.slug})`);
    return <div className="page movies-profile"> FormattedMessage id="app.404" </div>

  } else {

    const movie = props.document;
    // console.log(`  Movie (_id/slug: ${props.documentId || props.slug})`);
    console.log(movie);
    return (
      <div>MoofiePage</div>
    )
  }
}

MoofiePage.displayName = "moofiePage";

const options = {
  collection: Moofies,
  queryName: 'moofiesSingleQuery',
  fragmentName: 'MoofiePageFragment',
};

registerComponent('MoofiePage', MoofiePage, withCurrentUser, [withDocument, options]);
// registerComponent('MoofiePage', MoofiePage, withCurrentUser, [withDocument, options]);
