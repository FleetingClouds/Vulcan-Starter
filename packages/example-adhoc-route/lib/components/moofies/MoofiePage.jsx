import { Components, registerComponent, withDocument, withCurrentUser } from 'meteor/vulcan:core';
import React from 'react';
import { FormattedMessage } from 'meteor/vulcan:i18n';
import Moofies from '../../modules/moofies/collection.js';
const LG = (ln, msg) => console.log('Within %s @ %s ...\n  | %s', module.id, ln, msg);
const MRK = (chr, cnt) => console.log(chr.repeat(cnt));

const MoofiePage = (props) => {

  if (props.loading) {

    return <div className="page moofies-profile"><Components.Loading/></div>

  } else if (!props.document) {

    console.log(`// missing moofie (_id/slug: ${props.documentId || props.slug})`);
    return <div className="page moofies-profile"><FormattedMessage id="app.404"/></div>

  } else {

    const moofie = props.document;

    // console.log(moofie);
    // MRK('~  ', 20);
    const terms = {view: "moofiePosts", moofieId: moofie._id};

    return (
      <div className="page users-profile">
        {moofie.name
          ? (
              <div>
                <div><b>Name</b> : {moofie.name} ({moofie.year})</div>
                <div><b>Review</b> : {moofie.review}</div>
              </div>
            )
          : ( <div>Misfire.  Try again.</div> )
        }
      </div>
    )
  }
}

MoofiePage.propTypes = {
  // document: PropTypes.object.isRequired,
}

MoofiePage.displayName = "MoofiePage";

const options = {
  collection: Moofies,
  queryName: 'moofiesSingleQuery',
  fragmentName: 'MoofiePageFragment',
};

registerComponent('MoofiePage', MoofiePage, withCurrentUser, [withDocument, options]);
