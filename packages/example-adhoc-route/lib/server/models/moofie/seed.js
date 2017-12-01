import controller from './controller';
import seeds from './seeds.json';

export default () => {

  controller.findAndCountAll({}).then( (rslt) => {
    if ( rslt.count < 1 ) {
      console.log('<|| creating dummy movies ||>');
      seeds.data.forEach( document => {
        console.log(' Create :: ', document);
        controller.create( null, document );
      });
    }
  });
}
