/*

Define the three default mutations:

- new (e.g.: moofiesNew(document: moofiesInput) : Moofie )
- edit (e.g.: moofiesEdit(documentId: String, set: moofiesInput, unset: moofiesUnset) : Moofie )
- remove (e.g.: moofiesRemove(documentId: String) : Moofie )

Each mutation has:

- A name
- A check function that takes the current user and (optionally) the document affected
- The actual mutation

*/

import { newMutation, editMutation, removeMutation, Utils } from 'meteor/vulcan:core';
import Users from 'meteor/vulcan:users';

const mutations = {

  new: {

    name: 'moofiesNew',

    check(user) {
      if (!user) return false;
      return Users.canDo(user, 'moofies.new');
    },

    mutation(root, {document}, context) {

      Utils.performCheck(this.check, context.currentUser, document);

      return newMutation({
        collection: context.Moofies,
        document: document,
        currentUser: context.currentUser,
        validate: true,
        context,
      });
    },

  },

  edit: {

    name: 'moofiesEdit',

    check(user, document) {
      if (!user || !document) return false;
      return Users.owns(user, document) ? Users.canDo(user, 'moofies.edit.own') : Users.canDo(user, `moofies.edit.all`);
    },

    mutation(root, {documentId, set, unset}, context) {

      const document = context.Moofies.findOne(documentId);
      Utils.performCheck(this.check, context.currentUser, document);

      return editMutation({
        collection: context.Moofies,
        documentId: documentId,
        set: set,
        unset: unset,
        currentUser: context.currentUser,
        validate: true,
        context,
      });
    },

  },

  remove: {

    name: 'moofiesRemove',

    check(user, document) {
      if (!user || !document) return false;
      return Users.owns(user, document) ? Users.canDo(user, 'moofies.remove.own') : Users.canDo(user, `moofies.remove.all`);
    },

    mutation(root, {documentId}, context) {

      const document = context.Moofies.findOne(documentId);
      Utils.performCheck(this.check, context.currentUser, document);

      return removeMutation({
        collection: context.Moofies,
        documentId: documentId,
        currentUser: context.currentUser,
        validate: true,
        context,
      });
    },

  },

};

export default mutations;
