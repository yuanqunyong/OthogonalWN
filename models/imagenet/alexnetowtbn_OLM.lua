--[[
 this model is originally from: https://github.com/soumith/imagenet-multiGPU.torch
 We replace the SpatialConvolution layer with our Orthogonal rectangular weight layer
 ]]--


require 'nn'
require 'cunn'
require 'cudnn'
require '../../module/spatial/cudnn_Spatial_Weight_DBN_Row'

function createModel(opt)
   -- from https://code.google.com/p/cuda-convnet2/source/browse/layers/layers-imagenet-1gpu.cfg
   -- this is AlexNet that was presented in the One Weird Trick paper. http://arxiv.org/abs/1404.5997
   local features = nn.Sequential()
   features:add(cudnn.Spatial_Weight_DBN_Row(3,64,opt.m_perGroup,11,11,4,4,2,2))       -- 224 -> 55
   features:add(nn.SpatialBatchNormalization(64,1e-3))
   features:add(nn.ReLU(true))
   features:add(nn.SpatialMaxPooling(3,3,2,2))                   -- 55 ->  27
   features:add(cudnn.Spatial_Weight_DBN_Row(64,192,opt.m_perGroup,5,5,1,1,2,2))       --  27 -> 27
   features:add(nn.SpatialBatchNormalization(192,1e-3))
   features:add(nn.ReLU(true))
   features:add(nn.SpatialMaxPooling(3,3,2,2))                   --  27 ->  13
   features:add(cudnn.Spatial_Weight_DBN_Row(192,384,opt.m_perGroup,3,3,1,1,1,1))      --  13 ->  13
   features:add(nn.SpatialBatchNormalization(384,1e-3))
   features:add(nn.ReLU(true))
   features:add(cudnn.Spatial_Weight_DBN_Row(384,256,opt.m_perGroup,3,3,1,1,1,1))      --  13 ->  13
   features:add(nn.SpatialBatchNormalization(256,1e-3))
   features:add(nn.ReLU(true))
   features:add(cudnn.Spatial_Weight_DBN_Row(256,256,opt.m_perGroup,3,3,1,1,1,1))      --  13 ->  13
   features:add(nn.SpatialBatchNormalization(256,1e-3))
   features:add(nn.ReLU(true))
   features:add(nn.SpatialMaxPooling(3,3,2,2))                   -- 13 -> 6

   features:cuda()
  -- features = makeDataParallel(features, nGPU) -- defined in util.lua

   local classifier = nn.Sequential()
   classifier:add(nn.View(256*6*6))

   classifier:add(nn.Dropout(0.5))
   classifier:add(nn.Linear(256*6*6, 4096))
   classifier:add(nn.BatchNormalization(4096, 1e-3))
   classifier:add(nn.ReLU())

   classifier:add(nn.Dropout(0.5))
   classifier:add(nn.Linear(4096, 4096))
   classifier:add(nn.BatchNormalization(4096, 1e-3))
   classifier:add(nn.ReLU())

   classifier:add(nn.Linear(4096, 1000))
   classifier:add(nn.LogSoftMax())

   classifier:cuda()

   local model = nn.Sequential():add(features):add(classifier)
   model.imageSize = 256
   model.imageCrop = 224

   return model
end

return createModel

