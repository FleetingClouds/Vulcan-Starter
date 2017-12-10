/*

Three resolvers are defined:

- list (e.g.: moofiesList(terms: JSON, offset: Int, limit: Int) )
- single (e.g.: moofiesSingle(_id: String) )
- listTotal (e.g.: moofiesTotal )


*/
const LG = (ln, msg) => console.log('Within %s @ %s ...\n  | %s', module.id, ln, msg);
const MRK = (chr, cnt) => console.log(chr.repeat(cnt));

// basic list, single, and total query resolvers
const resolvers = {

  list: {

    name: 'moofiesList',

    async resolver(root, {terms = {}}, context, info) {
      let {selector, options} = await context.Moofies.getParameters(terms, {}, context.currentUser);
      return context.Moofies.find(selector, options).fetch();
    },

  },

  single: {

    name: 'moofiesSingle',

    resolver(root, parms, context) {
      const {documentId, slug} = parms;
      // LG(slug);
      // LG('---------');

      let parm = slug
          ? JSON.parse(slug)
          : {_id: documentId}

      return context.Users.restrictViewableFields(
        context.currentUser,
        context.Moofies,
        context.Moofies.findOne(parm).dataValues
      );
    },

  },

  total: {

    name: 'moofiesTotal',

    async resolver(root, {terms = {}}, context) {
      const {selector, options} = await context.Moofies.getParameters(terms, {}, context.currentUser);
      return context.Moofies.find(selector, options).count();
    },

  }
};

export default resolvers;
