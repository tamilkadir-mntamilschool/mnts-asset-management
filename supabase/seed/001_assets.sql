insert into public.assets (user_id, name, category, location, description)
values
  (auth.uid(), 'Forklift FL-12', 'Material Handling', 'Dock 2', 'Primary dock forklift'),
  (auth.uid(), 'CNC Router 7B', 'Fabrication', 'Plant 1', 'Spindle vibration reported'),
  (auth.uid(), 'Chiller Unit 4', 'Facilities', 'Rooftop', 'Awaiting compressor replacement'),
  (auth.uid(), 'Pallet Jack PJ-03', 'Material Handling', 'Warehouse', 'Battery replaced'),
  (auth.uid(), 'Packaging Line 2', 'Assembly', 'Plant 2', 'Calibrated last week');
