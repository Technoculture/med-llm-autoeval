#!/bin/bash

start=$(date +%s)

# Install dependencies
apt update
apt install -y screen vim git-lfs
screen

# Install common libraries
pip install -q requests accelerate sentencepiece pytablewriter einops protobuf
# Hugging Face login
huggingface-cli login --token $HF_TOKEN

if [ "$DEBUG" == "True" ]; then
    echo "Launch LLM AutoEval in debug mode"
fi

# Run evaluation
if [ "$BENCHMARK" == "nous" ]; then
    git clone -b add-agieval https://github.com/dmahan93/lm-evaluation-harness
    cd lm-evaluation-harness
    pip install -e .

    benchmark="agieval"
    python main.py \
        --model hf-causal \
        --model_args pretrained=$MODEL,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks agieval_aqua_rat,agieval_logiqa_en,agieval_lsat_ar,agieval_lsat_lr,agieval_lsat_rc,agieval_sat_en,agieval_sat_en_without_passage,agieval_sat_math \
        --device cuda:0 \
        --batch_size auto \
        --output_path ./${benchmark}.json

    benchmark="gpt4all"
    python main.py \
        --model hf-causal \
        --model_args pretrained=$MODEL,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks hellaswag,openbookqa,winogrande,arc_easy,arc_challenge,boolq,piqa \
        --device cuda:0 \
        --batch_size auto \
        --output_path ./${benchmark}.json

    benchmark="truthfulqa"
    python main.py \
        --model hf-causal \
        --model_args pretrained=$MODEL,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks truthfulqa_mc \
        --device cuda:0 \
        --batch_size auto \
        --output_path ./${benchmark}.json

    benchmark="bigbench"
    python main.py \
        --model hf-causal \
        --model_args pretrained=$MODEL,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks bigbench_causal_judgement,bigbench_date_understanding,bigbench_disambiguation_qa,bigbench_geometric_shapes,bigbench_logical_deduction_five_objects,bigbench_logical_deduction_seven_objects,bigbench_logical_deduction_three_objects,bigbench_movie_recommendation,bigbench_navigate,bigbench_reasoning_about_colored_objects,bigbench_ruin_names,bigbench_salient_translation_error_detection,bigbench_snarks,bigbench_sports_understanding,bigbench_temporal_sequences,bigbench_tracking_shuffled_objects_five_objects,bigbench_tracking_shuffled_objects_seven_objects,bigbench_tracking_shuffled_objects_three_objects \
        --device cuda:0 \
        --batch_size auto \
        --output_path ./${benchmark}.json

    end=$(date +%s)
    echo "Elapsed Time: $(($end-$start)) seconds"
    
    python ../med-llm-autoeval/main.py . $(($end-$start))

elif [ "$BENCHMARK" == "openllm" ]; then
    git clone https://github.com/EleutherAI/lm-evaluation-harness
    cd lm-evaluation-harness
    pip install -e ".[vllm,promptsource]"
    pip install langdetect immutabledict

    benchmark="arc"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks arc_challenge \
        --num_fewshot 25 \
        --batch_size auto \
        --output_path ./${benchmark}.json

    benchmark="hellaswag"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks hellaswag \
        --num_fewshot 10 \
        --batch_size auto \
        --output_path ./${benchmark}.json

    # benchmark="mmlu"
    # lm_eval --model vllm \
    #     --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
    #     --tasks mmlu \
    #     --num_fewshot 5 \
    #     --batch_size auto \
    #     --verbosity DEBUG \
    #     --output_path ./${benchmark}.json
    
    benchmark="truthfulqa"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks truthfulqa \
        --num_fewshot 0 \
        --batch_size auto \
        --output_path ./${benchmark}.json
    
    benchmark="winogrande"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks winogrande \
        --num_fewshot 5 \
        --batch_size auto \
        --output_path ./${benchmark}.json
    
    benchmark="gsm8k"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks gsm8k \
        --num_fewshot 5 \
        --batch_size auto \
        --output_path ./${benchmark}.json

    end=$(date +%s)
    echo "Elapsed Time: $(($end-$start)) seconds"
    
    python ../med-llm-autoeval/main.py . $(($end-$start))
elif [ "$BENCHMARK" == "medical" ]; then

    git clone https://github.com/EleutherAI/lm-evaluation-harness
    cd lm-evaluation-harness
    pip install -e ".[vllm,promptsource]"
    pip install langdetect immutabledict

    benchmark="medmcqa"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks medmcqa\
        --num_fewshot 3 \
        --batch_size auto \
        --output_path ./${benchmark}.json
    
    benchmark="pubmedqa"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks pubmedqa\
        --num_fewshot 3 \
        --batch_size auto \
        --output_path ./${benchmark}.json

    benchmark="medqa_4options"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks medqa_4options\
        --num_fewshot 3 \
        --batch_size auto \
        --output_path ./${benchmark}.json
    
    benchmark="mmlu_medical_genetics"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks mmlu_medical_genetics\
        --num_fewshot 5 \
        --batch_size auto \
        --output_path ./${benchmark}.json

    benchmark="mmlu_anatomy"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks mmlu_anatomy\
        --num_fewshot 5 \
        --batch_size auto \
        --output_path ./${benchmark}.json

    benchmark="mmlu_clinical_knowledge"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks mmlu_clinical_knowledge\
        --num_fewshot 5 \
        --batch_size auto \
        --output_path ./${benchmark}.json

    benchmark="mmlu_college_medicine"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks mmlu_college_medicine\
        --num_fewshot 5 \
        --batch_size auto \
        --output_path ./${benchmark}.json

    benchmark="mmlu_professional_medicine"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks mmlu_professional_medicine\
        --num_fewshot 5 \
        --batch_size auto \
        --output_path ./${benchmark}.json

    benchmark="mmlu_college_biology"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks mmlu_college_biology\
        --num_fewshot 5 \
        --batch_size auto \
        --output_path ./${benchmark}.json

    end=$(date +%s)
    echo "Elapsed Time: $(($end-$start)) seconds"
    
    python ../med-llm-autoeval/main.py . $(($end-$start))

elif [ "$BENCHMARK" == "medical-openllm" ]; then

    git clone https://github.com/EleutherAI/lm-evaluation-harness
    cd lm-evaluation-harness
    # pip install -e ".[vllm,promptsource]"
    pip install -e ".[vllm]"
    pip install langdetect immutabledict

    benchmark="medmcqa"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks medmcqa\
        --num_fewshot 3 \
        --batch_size auto \
        --output_path ./${benchmark}.json
    
    benchmark="pubmedqa"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks pubmedqa\
        --num_fewshot 3 \
        --batch_size auto \
        --output_path ./${benchmark}.json

    benchmark="medqa_4options"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks medqa_4options\
        --num_fewshot 3 \
        --batch_size auto \
        --output_path ./${benchmark}.json
    
    benchmark="mmlu_medical_genetics"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks mmlu_medical_genetics\
        --num_fewshot 5 \
        --batch_size auto \
        --output_path ./${benchmark}.json

    benchmark="mmlu_anatomy"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks mmlu_anatomy\
        --num_fewshot 5 \
        --batch_size auto \
        --output_path ./${benchmark}.json

    benchmark="mmlu_clinical_knowledge"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks mmlu_clinical_knowledge\
        --num_fewshot 5 \
        --batch_size auto \
        --output_path ./${benchmark}.json

    benchmark="mmlu_college_medicine"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks mmlu_college_medicine\
        --num_fewshot 5 \
        --batch_size auto \
        --output_path ./${benchmark}.json

    benchmark="mmlu_professional_medicine"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks mmlu_professional_medicine\
        --num_fewshot 5 \
        --batch_size auto \
        --output_path ./${benchmark}.json

    benchmark="mmlu_college_biology"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks mmlu_college_biology\
        --num_fewshot 5 \
        --batch_size auto \
        --output_path ./${benchmark}.json

    benchmark="truthfulqa"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks truthfulqa\
        --num_fewshot 25 \
        --batch_size auto \
        --output_path ./${benchmark}.json

    benchmark="winogrande"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks winogrande \
        --num_fewshot 5 \
        --batch_size auto \
        --output_path ./${benchmark}.json
    
    benchmark="gsm8k"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks gsm8k \
        --num_fewshot 5 \
        --batch_size auto \
        --output_path ./${benchmark}.json

    benchmark="arc"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks arc_challenge \
        --num_fewshot 25 \
        --batch_size auto \
        --output_path ./${benchmark}.json

    benchmark="hellaswag"
    lm_eval --model vllm \
        --model_args pretrained=${MODEL},dtype=auto,gpu_memory_utilization=0.8,trust_remote_code=$TRUST_REMOTE_CODE \
        --tasks hellaswag \
        --num_fewshot 10 \
        --batch_size auto \
        --output_path ./${benchmark}.json

    end=$(date +%s)
    echo "Elapsed Time: $(($end-$start)) seconds"
    
    python ../med-llm-autoeval/main.py . $(($end-$start))
    
else
    echo "Error: Invalid BENCHMARK value. Please set BENCHMARK to 'nous' or 'openllm' or 'medical' or 'medical-openllm'."
fi

if [ "$DEBUG" == "False" ]; then
    runpodctl remove pod $RUNPOD_POD_ID
fi
sleep infinity
