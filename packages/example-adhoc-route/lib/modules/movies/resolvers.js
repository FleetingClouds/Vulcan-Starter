/*

Three resolvers are defined:

- list (e.g.: moviesList(terms: JSON, offset: Int, limit: Int) )
- single (e.g.: moviesSingle(_id: String) )
- listTotal (e.g.: moviesTotal )

*/

// basic list, single, and total query resolvers
const resolvers = {

  list: {

    name: 'moviesList',

    async resolver(root, {terms = {}}, context, info) {
      let {selector, options} = await context.Movies.getParameters(terms, {}, context.currentUser);
      return context.Movies.find(selector, options).fetch();
    },

  },

  single: {
    
    name: 'moviesSingle',

    resolver(root, parms, context) {
      const {documentId, slug} = parms;

      return context.Users.restrictViewableFields(
        context.currentUser,
        context.Movies,
        slug
          ? context.Movies.findOne(JSON.parse(slug))
          : context.Movies.findOne({_id: documentId})
      );
    },
  
  },

  total: {
    
    name: 'moviesTotal',
    
    async resolver(root, {terms = {}}, context) {
      const {selector, options} = await context.Movies.getParameters(terms, {}, context.currentUser);
      return context.Movies.find(selector, options).count();
    },
  
  }
};

export default resolvers;