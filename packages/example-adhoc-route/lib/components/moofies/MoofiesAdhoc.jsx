import { Components, registerComponent } from 'meteor/vulcan:core';
import React from 'react';

const MoofiesAdhoc = (props, context) => {

  let adhoc=JSON.stringify(props.location.query);
  return <Components.MoofiePage slug={adhoc} />

}


MoofiesAdhoc.displayName = "MoofiesAdhoc";

registerComponent('MoofiesAdhoc', MoofiesAdhoc);
