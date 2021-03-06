from pyramid.view import view_config
#get all classes from the models to be used
from models import *
import whisperer
import numpy

@view_config(name='add', context='whisperer.models.UserResource',
             renderer='json')
def add_user(request):
	name = request.POST.get('name')
	if not name:
		return dict(error = 'no name provided')	
	session = DBSession()
	if not session.query(User).filter(User.name.in_([name])).all():
		user_added = User(name=name)
		session.add(user_added)
		session.flush()
		return dict(name=user_added.name, id=user_added.id)        
	return dict(error = 'Username already used, please insert another')

#curl -X POST  http://127.0.0.1:6543/item/add -d "name=hello"
@view_config(name='add', context='whisperer.models.ItemResource',
             renderer='json')
def add_Item(request):
	name = request.POST.get('name')
	if not name:
		return dict(error = 'no name provided')
	session = DBSession()
	if not session.query(Item).filter(Item.name.in_([name])).all():			
		item_added = Item(name=name)
		session.add(item_added)
		session.flush()
		return dict(name = item_added.name, id = item_added.id)                			
	return dict(message = 'Item already exists, please insert another')	

@view_config(name='addMetadata', context='whisperer.models.Item',
             renderer='json')
def add_Metadata_to_Item(context, request):
	name = request.POST.get('name')
	mtype = request.POST.get('type')
	lang = request.POST.get('lang')
	if not name or not mtype or not lang:
		return dict(error = 'parameters missing')
	session = DBSession()
	try:
		metadata = session.query(Metadata).filter(Metadata.name == name).one()
	except NoResultFound:			
		metadata = Metadata(name = name, type = mtype, lang =lang)
		session.add(metadata)
		session.flush()
	metadata.items.append(context.__parent__)
	return dict(item_name = context.__parent__.name, id = metadata.id,
		name = metadata.name, type = metadata.type, lang = metadata.lang)                			      			
	
#curl -X POST  http://127.0.0.1:6543/item/1/addRating -d "userid=1&rating=4"

@view_config(name='addRating', context='whisperer.models.Item',
             renderer='json')
def add_rating(context, request):
	userid = request.POST.get('userid')
	rating = request.POST.get('rating')
	if not rating or not userid:
		return dict(error = 'parameters missing')
	session = DBSession()
	try:
		user = session.query(User).filter(User.id == userid).one()
	except NoResultFound:
		return dict(error= 'user not found')
	r = Rating(rating = rating, user=user)
	r.item = context.__parent__
	session.add(r)
	session.flush()
	return dict(id = r.id, userid=r.user_id, itemid=r.item_id)   

#curl -X POST  http://127.0.0.1:6543/user/1/getRec -d "alg=AsySVD"
@view_config(name='getRec', context='whisperer.models.User',
             renderer='json')            
def get_recommendation(context, request):
	w = whisperer.Whisperer()
	algname = request.POST.get('alg')
	if algname not in w.get_algnames():
		return dict(error = '"alg" parameter missing or algorithm not found')
	res = w.get_rec(algname, context.__parent__)
	if algname == "AsySVD":
		return dict([(i+1,r[0])for i,r in enumerate(res)])
	return dict([(col+1,value)for (row,col),value in numpy.ndenumerate(res) if not numpy.isnan(value)])

#curl http://127.0.0.1:6543/algnames
@view_config(name='algnames', context='whisperer.models.MyApp',
             renderer='json')            
def get_algnames(context, request):
	w = whisperer.Whisperer()
	return dict(algnames=w.get_algnames())

#curl http://127.0.0.1:6543/alg_date -d "alg=AsySVD"
@view_config(name='alg_date', context='whisperer.models.Algorithm',
             renderer='json')            
def get_alg_date(context, request):
	w = whisperer.Whisperer()
	try:
		date = context.date
	except NoResultFound:
		return dict(error= 'algorithm model creation date not found')
	return dict(date=date)
