#!/bin/bash
# Copyright 2020 Google and DeepMind.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

REPO=$PWD
MODEL=${1:-bert-base-multilingual-based}
GPU=${2:-0}
DATA_DIR=${3:-"$REPO/download/"}
OUT_DIR=${4:-"$REPO/outputs/"}

set -ex
export CUDA_VISIBLE_DEVICES=$GPU

TASK='tatoeba'
TL='en'
MAXL=512
LC=""
LAYER=7
NLAYER=12
if [ $MODEL == "bert-base-multilingual-cased" ]; then
  MODEL_TYPE="bert"
  DIM=768
elif [ $MODEL == "xlm-mlm-100-1280" ] || [ $MODEL == "xlm-mlm-tlm-xnli15-1024" ]; then
  MODEL_TYPE="xlm"
  LC=" --do_lower_case"
  if [ $MODEL == "xlm-mlm-100-1280" ]; then
    DIM=1280
  elif [ $MODEL == "xlm-mlm-tlm-xnli15-1024" ]; then
    DIM=1024
  fi
elif [ $MODEL == "xlm-roberta-large" ] || [ $MODEL == "xlm-roberta-base" ]; then
  MODEL_TYPE="xlmr"
  if [ $MODEL == "xlm-roberta-large" ]; then
    DIM=1024
  elif [ $MODEL == "xlm-roberta-base" ]; then
    DIM=768
  NLAYER=24
  LAYER=13
  fi
elif [ $MODEL == "google/mt5-small" ] || [ $MODEL == "google/mt5-xxl" ]; then
  MODEL_TYPE="mt5"
  DIM=512
  NLAYER=24
  LAYER=13
elif [ $MODEL == "rembert" ]; then
  MODEL_TYPE="rembert"
  MODEL="google/rembert"
  DIM=1152
  NLAYER=24
  LAYER=13
fi

# Add fine-tuned model path here
#MODEL=/mnt/disk-1/models/squad/bert-base-multilingual-cased_LR?_EPOCH?_maxlen?_batchsize?_gradacc?

OUT=$OUT_DIR/$TASK/${MODEL}_${MAXL}/
#OUT=/content/gdrive/MyDrive/xtreme-master
mkdir -p $OUT
if [ $MODEL == "bert-base-multilingual-cased" ] || [ $MODEL == "xlm-mlm-100-1280" ] || [ $MODEL == "xlm-mlm-tlm-xnli15-1024" ] || [ $MODEL == "xlm-roberta-large" ] || [ $MODEL == "xlm-roberta-base" ]; then
  for SL in ar he vi id jv tl eu ml ta te af nl en de el bn hi mr ur fa fr it pt es bg ru ka ko th sw zh kk tr et fi hu az lt pl uk ro; do
    python $REPO/third_party/evaluate_retrieval.py \
      --model_type $MODEL_TYPE \
      --model_name_or_path $MODEL \
      --embed_size $DIM \
      --batch_size 100 \
      --task_name $TASK \
      --src_language $SL \
      --tgt_language en \
      --data_dir $DATA_DIR/$TASK/ \
      --max_seq_length $MAXL \
      --output_dir $OUT \
      --log_file embed-cosine \
      --num_layers $NLAYER \
      --dist cosine $LC \
      --specific_layer $LAYER
  done
elif [ $MODEL == "google/mt5-small" ] || [ $MODEL == "google/mt5-xxl" ]; then
  for SL in ar he vi id jv tl eu ml ta te af nl en de el bn hi mr ur fa fr it pt es bg ru ka ko th sw zh kk tr et fi hu az lt pl uk ro; do
    python $REPO/third_party/evaluate_retrieval_mT5.py \
      --model_type $MODEL_TYPE \
      --model_name_or_path $MODEL \
      --embed_size $DIM \
      --batch_size 100 \
      --task_name $TASK \
      --src_language $SL \
      --tgt_language en \
      --data_dir $DATA_DIR/$TASK/ \
      --max_seq_length $MAXL \
      --output_dir $OUT \
      --log_file embed-cosine \
      --num_layers $NLAYER \
      --dist cosine $LC \
      --specific_layer $LAYER
  done
elif [ $MODEL == "google/rembert" ]; then
  for SL in ar he vi id jv tl eu ml ta te af nl en de el bn hi mr ur fa fr it pt es bg ru ka ko th sw zh kk tr et fi hu az lt pl uk ro; do
    python $REPO/third_party/evaluate_retrieval_rembert.py \
      --model_type $MODEL_TYPE \
      --model_name_or_path $MODEL \
      --embed_size $DIM \
      --batch_size 100 \
      --task_name $TASK \
      --src_language $SL \
      --tgt_language en \
      --data_dir $DATA_DIR/$TASK/ \
      --max_seq_length $MAXL \
      --output_dir $OUT \
      --log_file embed-cosine \
      --num_layers $NLAYER \
      --dist cosine $LC \
      --specific_layer $LAYER
  done
fi
