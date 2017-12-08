/*

Three resolvers are defined:

- list (e.g.: moofiesList(terms: JSON, offset: Int, limit: Int) )
- single (e.g.: moofiesSingle(_id: String) )
- listTotal (e.g.: moofiesTotal )


*/
const LG = (msg) => console.log('Within %s...\n  |%s', module.id, msg);

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
      LG(slug);
      LG('---------');
      console.log(context.Moofies);

      return context.Users.restrictViewableFields(
        context.currentUser,
        context.Moofies,
        slug
          ? context.Moofies.findOne(JSON.parse(slug))
          : context.Moofies.findOne({_id: documentId})
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
